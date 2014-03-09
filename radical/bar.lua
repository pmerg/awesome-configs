local setmetatable,unpack,table = setmetatable,unpack,table
local base       = require( "radical.base"                 )
local color      = require( "gears.color"                  )
local wibox      = require( "wibox"                        )
local beautiful  = require( "beautiful"                    )
local cairo      = require( "lgi"                          ).cairo
local awful      = require( "awful"                        )
local util       = require( "awful.util"                   )
local fkey       = require( "radical.widgets.fkey"         )
local button     = require( "awful.button"                 )
local checkbox   = require( "radical.widgets.checkbox"     )
local item_style = require( "radical.item_style.arrow_single" )
local vertical   = require( "radical.layout.vertical"      )
local item_layout= require( "radical.item_layout.horizontal" )

local capi,module = { mouse = mouse , screen = screen, keygrabber = keygrabber },{}

local function get_direction(data)
  return "left" -- Nothing to do
end

local function set_position(self)
  return --Nothing to do
end

-- Draw the menu background
local function bg_draw(self, w, cr, width, height)
    cr:save()
    cr:set_source(color(self._data.bg))
    cr:rectangle(0,0,width,height)
    cr:fill()
    cr:restore()
  wibox.layout.margin.draw(self, w, cr, width, height)
end

local function setup_drawable(data)
  local internal = data._internal
  local get_map,set_map,private_data = internal.get_map,internal.set_map,internal.private_data

  --Init
  internal.margin = wibox.layout.margin()
  internal.margin._data = data
  internal.margin.draw = bg_draw

  internal.layout = internal.layout_func or wibox.layout.fixed.horizontal()
  internal.margin:set_widget(internal.layout)

  --Getters
  get_map.x         = function() return 0                                            end
  get_map.y         = function() return 0                                            end
  get_map.width     = function() return internal.margin.fix(internal.margin,9999,99) end
  get_map.height    = function() return beautiful.default_height                     end
  get_map.visible   = function() return true                                         end
  get_map.direction = function() return "left"                                       end
  get_map.margins   = function() return {left=0,right=0,top=0,bottom=0}              end

  -- This widget do not use wibox, so setup correct widget interface
  data.fit = internal.margin.fit
  data.draw = internal.margin.draw

  -- Swap / Move / Remove
  data:connect_signal("item::swapped",function(_,item1,item2,index1,index2)
    internal.layout.widgets[index1],internal.layout.widgets[index2] = internal.layout.widgets[index2],internal.layout.widgets[index1]
    internal.layout:emit_signal("widget::updated")
  end)
  data:connect_signal("item::moved",function(_,item,new_idx,old_idx)
    table.insert(internal.layout.widgets,new_idx,table.remove(internal.layout.widgets,old_idx))
    internal.layout:emit_signal("widget::updated")
  end)
  data:connect_signal("item::removed",function(_,item,old_idx)
    table.remove(internal.layout.widgets,old_idx)
    item.widget:disconnect_signal("widget::updated", internal.layout._emit_updated)
    internal.layout:emit_signal("widget::updated")
  end)
  data:connect_signal("item::appended",function(_,item)
    internal.layout:add(item.widget)
    internal.layout:emit_signal("widget::updated")
  end)
end

local function setup_buttons(data,item,args)
  local buttons = {}
  for i=1,10 do
    if args["button"..i] then
      buttons[#buttons+1] = button({},i,args["button"..i])
    end
  end

  -- Setup sub_menu
  if (item.sub_menu_m or item.sub_menu_f) and data.sub_menu_on >= base.event.BUTTON1 and data.sub_menu_on <= base.event.BUTTON3 then
    buttons[data.sub_menu_on] = item.widget:set_menu(item.sub_menu_m or item.sub_menu_f,data.sub_menu_on)
  end

  -- Scrool up
  if not buttons[4] then
    buttons[#buttons+1] = button({},4,function()
      data:scroll_up()
    end)
  end

  -- Scroll down
  if not buttons[5] then
    buttons[#buttons+1] = button({},5,function()
      data:scroll_down()
    end)
  end
  item.widget:buttons( util.table.join(unpack(buttons)))
end

local function setup_item(data,item,args)
  -- Add widgets
  data._internal.layout:add(item_layout(item,data,args))
  if data.select_on == base.event.HOVER then
    item.widget:connect_signal("mouse::enter", function() item.selected = true end)
    item.widget:connect_signal("mouse::leave", function() item.selected = false end)
  else
    item.widget:connect_signal("mouse::enter", function() item.hover = true end)
    item.widget:connect_signal("mouse::leave", function() item.hover = false end)
  end

  -- Setup buttons
  setup_buttons(data,item,args)
end

local function new(args)
    local args = args or {}
    args.internal = args.internal or {}
    args.internal.get_direction  = args.internal.get_direction  or get_direction
    args.internal.set_position   = args.internal.set_position   or set_position
    args.internal.setup_drawable = args.internal.setup_drawable or setup_drawable
    args.internal.setup_item     = args.internal.setup_item     or setup_item
    args.item_style = args.item_style or item_style
    args.sub_menu_on = args.sub_menu_on or base.event.BUTTON1
    local ret = base(args)
    ret:connect_signal("clear::menu",function(_,vis)
      ret._internal.layout:reset()
    end)
    ret:connect_signal("_hidden::changed",function(_,item)
      item.widget:emit_signal("widget::updated")
    end)
    return ret
end

function module.flex(args)
  local args = args or {}
  args.internal = args.internal or {}
  args.internal.layout_func = wibox.layout.flex.horizontal()
  local data = new(args)
  data._internal.text_fit = function(self,width,height) return width,height end
  return data
end

return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;