export type Enemy = {
    id :string,
    model :Model,
    special : {[string] : any},
    update :(self :Enemy) -> (),
}

return nil