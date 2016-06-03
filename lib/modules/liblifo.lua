
liblifo = {}

lifo = class(function(self)
	self.stack = {}
end)

function lifo:push(el)
	table.insert(self.stack, 1, el)
end

function lifo:pop()
	head = self.stack[1]
	table.remove(self.stack, 1)
	return head
end

function lifo:clear()
	self.stack = {}
end

function lifo:is_empty()
	return #self.stack == 0
end

liblifo.lifo = lifo

function libroutine()
	_G['liblifo'] = liblifo
end
