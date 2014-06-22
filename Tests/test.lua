function my_super_function( arg1, arg2 ) return arg1 + arg2 end

local LuaUnit = require('luaunit')
local AuraMastery = require('AuraMastery')

test_AuraMastery = {} 
    function test_AuraMastery:testShouldStartWithNoIcons()
    	local auraMastery = AuraMastery:new()
        assertEquals(#auraMastery.Icons, 0)
        assert(Window['SetBarColor'] == nil)
    end

    function test_AuraMastery:testShouldAddIconWhenAddIconCalled()
        local auraMastery = AuraMastery:new()
        local mock = LuaMock.new()
        mock:Mock(Window, 'SetBarColor', function(self)
        end)
        --function Window:SetBarColor(color)
        --end
        function Window:SetMax(color)
        end
        auraMastery:AddIcon()
        assertEquals(#auraMastery.Icons, 1)
    end

LuaMock = {}
LuaMock.__index = LuaMock

function LuaMock.new()
	local self = setmetatable({}, LuaMock)
	self.mocked = {}
	return self
end

function LuaMock:Mock(obj, func, mockFunc)
	self:MockObject(obj):MockFunction(func)

	obj[func] = mockFunction
end

function LuaMock:MockObject(obj)
	if self.mocked[obj] == nil then
		self.mocked[obj] = {}
	end
	return self.mocked[obj]
end

function LuaMock:RestoreAll()
	for _, obj in pairs(self.mocked) do
		obj:RestoreAll()
	end
end

MockObject = {}
function MockObject.new()
	local self = setmetatable({}, MockObject)
	self.functions = {}
	return self
end

function MockObject:MockFunction(func)
	if self.functions[func] == nil then
		self.functions[func] = MockedFunction.new(self, func)
	end
	return self.functions[func]
end

function MockObject:RestoreAll()
	for _, func in pairs(self.functions) do
		func:Restore()
	end
end

MockedFunction = {}
function MockedFunction.new(obj, func)
	local self = setmetatable({}, MockFunction)
	self.obj = obj
	self.func = func
	self.mockedFunction = obj[func]
	return self
end

function MockedFunction:Restore()
	obj[func] = self.mockedFunction
end