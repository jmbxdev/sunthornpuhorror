export type ChapterInfo = {
    map :string,
    enemies : {string}
}

local Chapters = {
    Baseplate = {
        map = "Baseplate",
        enemies = {
            "Writer"
        }
    }
}

local ChapterInfo = {}

function ChapterInfo.get(ChapterName :string)
    assert(Chapters[ChapterName],"Chapter not found")
    return Chapters[ChapterName]
end

return ChapterInfo