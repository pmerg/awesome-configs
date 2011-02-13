--Switch client with the keybpard by assigning a number to every client in a tag
--Requier fork of tasklist.lua to work (this is the backend)
--Author: Emmanuel Lepage Vallee <elv1313@gmail.com>

local setmetatable = setmetatable
local io = io
local ipairs = ipairs
local table = table
local print = print
local capi = { screen = screen,
               mouse = mouse,
               client = client}

module("clientSwitcher")

local data = {client = {}}
function new(screen, args) 
  return --Nothing to do
end

function assign(client, index)
  if client:tags()[1] == capi.screen[capi.mouse.screen]:tags()[1] then
    data.client[index] = client
  end
end

function switchTo(i)
  print("I am here "..i)
  if data.client[i] ~= nil then
    capi.client.focus = data.client[i]
  else
    print("nil")
  end
end

function reset()
  --data.client = {} --TODO restore this
end

setmetatable(_M, { __call = function(_, ...) return new(...) end })
