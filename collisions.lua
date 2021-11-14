local all_categories = (function()
    local categories = {}
    for i = 1,16 do
        table.insert(categories, i)
    end
    return categories
end)()

-- based on objects in /obj dir
-- in the form of ObjName = {{...categories}, {...masks}}
return {
    Default = {{1}, {}},
    Player = {{2}, {}},
    Ground = {{3}, {}},
    Projectile = {{4}, {2, 4}},
    Spear = {{5}, {5}},
    Ghost = {{16}, all_categories}
}