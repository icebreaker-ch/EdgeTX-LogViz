local Selector = {}
Selector.__index = Selector

Selector.STATE_IDLE = 0
Selector.STATE_SELECTED = 1
Selector.STATE_EDITING = 2

function Selector.new(values, index)
    local self = setmetatable({}, Selector)
    self.index = index or 1
    if values and #values > 0 then
        self.values = values
    else
        self.values = {"-"}
    end
    self.state = self.STATE_IDLE
    return self
end

-- Notify observer
function Selector:notify()
    if self.onChange then
        self.onChange(self.index)
    end
end

function Selector:setOnChange(f)
    self.onChange = f
end

function Selector:setValues(values)
    if values and #values > 0 then
        self.values = values
    else        
        self.values = {"-"}
    end
end

function Selector:setIndex(index)
    self.index = index
    self:notify()
end

function Selector:setState(newState)
    self.state = newState
end

function Selector:getState()
    return self.state
end

function Selector:getIndex()
    return self.index
end

function Selector:getValue()
    return self.values[self.index]
end

function Selector:getFlags()
    if self.state == self.STATE_IDLE then
        return 0
    elseif self.state == self.STATE_SELECTED then
        return INVERS
    elseif self.state == self.STATE_EDITING then
        return BLINK + INVERS
    end
end

function Selector:incValue()
    if self.index < #self.values then
        self.index = self.index + 1
        self:notify()
    end
end

function Selector:decValue()
    if self.index > 1 then
        self.index = self.index - 1
        self:notify()
    end
end

return Selector