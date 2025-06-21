local Button = {}
Button.__index = Button

Button.STATE = {
    IDLE = 0,
    SELECTED = 1
}

function Button.new(text)
    local self = setmetatable({}, Button)
    self.text = text
    self.state = self.STATE.IDLE
    return self
end

function Button:setText(text)
    self.text = text
end

function Button:setState(newState)
    self.state = newState
end

function Button:getState()
    return self.state
end

function Button:getText()
    return self.text
end

function Button:getFlags()
    if self.state == self.STATE.IDLE then
        return 0
    elseif self.state == self.STATE.SELECTED then
        return INVERS
    end
end

return Button