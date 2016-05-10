
-- libtest: library for testing scripts that test other things

Test = class(function(self, id, desc, f)
    self.id = id
    self.desc = desc
    self.testfunc = f
end)

function libroutine()
end
