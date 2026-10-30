--!optimize 2
--!strict

export type CleanupFunction = () -> ()

export type Promise = {
	getStatus: (self: Promise) -> string,
	cancel: (self: Promise) -> (),
	finally: (self: Promise, callback: (status: string) -> ()) -> Promise,
	[string]: any,
}

export type MethodName = string | boolean

export type Index = any

export type Connection = {
	connected: boolean,
	disconnect: (self: Connection) -> (),
}

export type Janitor = {
	currentlyCleaning: boolean,

	add: <T>(self: Janitor, object: T, methodName: MethodName?, index: Index?) -> T,
	addObject: <T, A...>(
		self: Janitor,
		constructor: { new: (A...) -> T },
		methodName: MethodName?,
		index: Index?,
		A...
	) -> T,
	addPromise: (self: Janitor, promise: Promise) -> Promise,
	remove: (self: Janitor, index: Index) -> Janitor,
	removeNoCleanup: (self: Janitor, index: Index) -> Janitor,
	removeList: (self: Janitor, ...Index) -> Janitor,
	removeListNoCleanup: (self: Janitor, ...Index) -> Janitor,
	get: (self: Janitor, index: Index) -> any?,
	getAll: (self: Janitor) -> { [Index]: any },

	cleanup: (self: Janitor) -> (),
	destroy: (self: Janitor) -> (),

	linkToInstance: (self: Janitor, instance: Instance, allowMultiple: boolean?) -> Connection,
	linkToInstances: (self: Janitor, ...Instance) -> Janitor,
	legacyLinkToInstance: (self: Janitor, instance: Instance, allowMultiple: boolean?) -> Connection,
}

type InternalJanitor = Janitor & {
	_methods: { [any]: MethodName }?,
	_indexMap: { [Index]: any }?,
	_suppressedInstance: Instance?,
	_destroyed: boolean,
}

local promiseStatusStarted: string = "Started"

local linkToInstanceKey: any = newproxy(false)

local janitor = {}
janitor.__index = janitor

function janitor.new(): Janitor
	local self = setmetatable({
		currentlyCleaning = false,
		_methods = nil :: { [any]: MethodName }?,
		_indexMap = nil,
		_suppressedInstance = nil,
		_destroyed = false,
	}, janitor)

	return (self :: any) :: Janitor
end

function janitor.is(object: any): boolean
	return type(object) == "table" and getmetatable(object) == janitor
end

local function cleanupEntry(object: any, methodName: MethodName, suppressedInstance: Instance?): ()
	if type(object) == "thread" then
		task.cancel(object :: thread)
		return
	end

	if suppressedInstance and object == suppressedInstance and (methodName == "Destroy" or methodName == "destroy") then
		return
	end

	if methodName == true then
		(object :: CleanupFunction)()
	elseif methodName == "Disconnect" then
		local method = (object :: any).Disconnect or (object :: any).disconnect
		if type(method) == "function" then
			(method :: any)(object)
		end
	elseif methodName == "Destroy" then
		local method = (object :: any).Destroy or (object :: any).destroy
		if type(method) == "function" then
			(method :: any)(object)
		end
	else
		local method: any = (object :: any)[methodName]
		if type(method) == "function" then
			(method :: any)(object)
		end
	end
end

local function removeByIndex(self: InternalJanitor, index: Index): ()
	local indexMap = self._indexMap
	if not indexMap then
		return
	end

	local object: any = indexMap[index]
	if object == nil then
		return
	end

	local methods = self._methods
	local methodName: MethodName = if methods then methods[object] else "Destroy"
	indexMap[index] = nil
	if methods then
		methods[object] = nil
	end

	cleanupEntry(object, methodName, self._suppressedInstance)
end

local function removeByIndexNoCleanup(self: InternalJanitor, index: Index): ()
	local indexMap = self._indexMap
	if not indexMap then
		return
	end

	local object: any = indexMap[index]
	if object == nil then
		return
	end

	indexMap[index] = nil
	local methods = self._methods
	if methods then
		methods[object] = nil
	end
end

local function addEntry<T>(self: InternalJanitor, object: T, methodName: MethodName?, index: Index?): T
	if self._destroyed then
		return object
	end

	if index ~= nil then
		removeByIndex(self, index)

		local indexMap = self._indexMap
		if not indexMap then
			indexMap = {}
			self._indexMap = indexMap
		end
		(indexMap :: { [Index]: any })[index] = object
	end

	local resolvedMethod: MethodName
	if methodName then
		resolvedMethod = methodName
	else
		local t = typeof(object)
		if t == "function" then
			resolvedMethod = true
		elseif t == "RBXScriptConnection" then
			resolvedMethod = "Disconnect"
		else
			resolvedMethod = "Destroy"
		end
	end

	local methods: { [any]: MethodName } = self._methods or {}
	if not self._methods then
		self._methods = methods
	end
	methods[object] = resolvedMethod

	return object
end

function janitor.add<T>(self: any, object: T, methodName: MethodName?, index: Index?): T
	return addEntry(self :: InternalJanitor, object, methodName, index)
end

function janitor.addObject<T, A...>(
	self: any,
	constructor: { new: (A...) -> T },
	methodName: MethodName?,
	index: Index?,
	...: A...
): T
	local instance: T = constructor.new(...)
	return addEntry(self :: InternalJanitor, instance, methodName, index)
end

function janitor.addPromise(self: any, promise: Promise): Promise
	local self_: InternalJanitor = self
	if promise:getStatus() ~= promiseStatusStarted then
		return promise
	end

	addEntry(self_, promise, "cancel", nil)

	promise:finally(function(_status: string): ()
		if not self_._destroyed then
			local methods = self_._methods
			if methods then
				methods[promise] = nil
			end
		end
	end)

	return promise
end

function janitor.remove(self: any, index: Index): Janitor
	local self_: InternalJanitor = self
	if self_._destroyed then
		return self
	end

	removeByIndex(self_, index)
	return self
end

function janitor.removeNoCleanup(self: any, index: Index): Janitor
	local self_: InternalJanitor = self
	if self_._destroyed then
		return self
	end

	removeByIndexNoCleanup(self_, index)
	return self
end

function janitor.removeList(self: any, ...: Index): Janitor
	local self_: InternalJanitor = self
	if self_._destroyed then
		return self
	end

	local length: number = select("#", ...)
	if length == 1 then
		removeByIndex(self_, ...)
		return self
	elseif length == 2 then
		local indexA: Index, indexB: Index = ...
		removeByIndex(self_, indexA)
		removeByIndex(self_, indexB)
		return self
	elseif length == 3 then
		local indexA: Index, indexB: Index, indexC: Index = ...
		removeByIndex(self_, indexA)
		removeByIndex(self_, indexB)
		removeByIndex(self_, indexC)
		return self
	end

	for i: number = 1, length do
		removeByIndex(self_, select(i, ...))
	end

	return self
end

function janitor.removeListNoCleanup(self: any, ...: Index): Janitor
	local self_: InternalJanitor = self
	if self_._destroyed then
		return self
	end

	local length: number = select("#", ...)
	if length == 1 then
		removeByIndexNoCleanup(self_, ...)
		return self
	elseif length == 2 then
		local indexA: Index, indexB: Index = ...
		removeByIndexNoCleanup(self_, indexA)
		removeByIndexNoCleanup(self_, indexB)
		return self
	elseif length == 3 then
		local indexA: Index, indexB: Index, indexC: Index = ...
		removeByIndexNoCleanup(self_, indexA)
		removeByIndexNoCleanup(self_, indexB)
		removeByIndexNoCleanup(self_, indexC)
		return self
	end

	for i: number = 1, length do
		removeByIndexNoCleanup(self_, select(i, ...))
	end

	return self
end

function janitor.get(self: any, index: Index): any?
	local self_: InternalJanitor = self
	if self_._destroyed then
		return nil
	end

	local indexMap = self_._indexMap
	if not indexMap then
		return nil
	end

	return indexMap[index]
end

function janitor.getAll(self: any): { [Index]: any }
	local self_: InternalJanitor = self
	if self_._destroyed then
		return {}
	end

	local indexMap = self_._indexMap
	if not indexMap then
		return {}
	end

	return table.freeze(table.clone(indexMap))
end

function janitor.cleanup(self: any): ()
	local self_: InternalJanitor = self
	if self_.currentlyCleaning or self_._destroyed then
		return
	end

	self_.currentlyCleaning = true

	local methods = self_._methods
	local suppressed: Instance? = self_._suppressedInstance

	if methods then
		for object, methodName in methods do
			methods[object] = nil
			cleanupEntry(object, methodName, suppressed)
		end
	end

	local indexMap = self_._indexMap
	if indexMap then
		table.clear(indexMap)
	end

	self_.currentlyCleaning = false
end

function janitor.destroy(self: any): ()
	local self_: InternalJanitor = self
	if self_._destroyed then
		return
	end

	self_._destroyed = true
	self:cleanup()
	setmetatable(self_, nil)
end

local ConnectionImpl = {}
ConnectionImpl.__index = ConnectionImpl

function ConnectionImpl.disconnect(self: any)
	if self.connected then
		self.connected = false
		local rbxConn = self._rbxConn
		if rbxConn then
			rbxConn:Disconnect()
			self._rbxConn = nil
		end
		local owner: InternalJanitor? = self._owner
		if owner and not owner._destroyed then
			removeByIndexNoCleanup(owner, self._linkKey)
		end
		self._owner = nil
	end
end

local function makeConnection(rbxConn: RBXScriptConnection, owner: InternalJanitor, linkKey: any): Connection
	return setmetatable({
		connected = true,
		_rbxConn = rbxConn,
		_owner = owner,
		_linkKey = linkKey,
	}, ConnectionImpl) :: any
end

local function linkToInstanceImpl(self: InternalJanitor, instance: Instance, allowMultiple: boolean?): Connection
	if self._destroyed then
		local dead = setmetatable({ connected = false, _rbxConn = nil, _owner = nil, _linkKey = nil }, ConnectionImpl)
		return dead :: any
	end

	local linkKey: any = if allowMultiple then newproxy(false) else linkToInstanceKey

	local connection: RBXScriptConnection = instance.Destroying:Connect(function(): ()
		self._suppressedInstance = instance
		janitor.cleanup(self)
		self._suppressedInstance = nil
	end)

	local janitorConn: Connection = makeConnection(connection, self, linkKey)

	addEntry(self, janitorConn, "Disconnect", linkKey)

	return janitorConn
end

function janitor.linkToInstance(self: any, instance: Instance, allowMultiple: boolean?): Connection
	return linkToInstanceImpl(self :: InternalJanitor, instance, allowMultiple)
end

function janitor.linkToInstances(self: any, ...: Instance): Janitor
	local self_: InternalJanitor = self
	local manualCleanup: Janitor = janitor.new()
	local length: number = select("#", ...)

	for i: number = 1, length do
		local instance: any = select(i, ...)
		if typeof(instance) == "Instance" then
			local conn: Connection = linkToInstanceImpl(self_, instance, true)
			manualCleanup:add(conn, "Disconnect")
		end
	end

	return manualCleanup
end

function janitor.legacyLinkToInstance(self: any, instance: Instance, allowMultiple: boolean?): Connection
	return linkToInstanceImpl(self :: InternalJanitor, instance, allowMultiple)
end

function janitor.__tostring(_self: Janitor): string
	return "Janitor"
end

return janitor
