-- Utility functions for nvim configuration

local M = {}

-- Show highlight groups under cursor
function M.show_highlight_groups()
  local line = vim.fn.line '.'
  local col = vim.fn.col '.'
  local synstack = vim.fn.synstack(line, col)

  if #synstack == 0 then
    print 'No highlight groups found'
    return
  end

  local groups = {}
  for _, id in ipairs(synstack) do
    local name = vim.fn.synIDattr(id, 'name')
    local trans = vim.fn.synIDattr(vim.fn.synIDtrans(id), 'name')
    table.insert(groups, name .. (trans ~= name and ' -> ' .. trans or ''))
  end

  print('Highlight groups: ' .. table.concat(groups, ', '))
end

-- Color utility functions for RGB/HSL operations
function M.rgb_to_hsl(r, g, b)
  r, g, b = r / 255, g / 255, b / 255
  local max = math.max(r, g, b)
  local min = math.min(r, g, b)
  local h, s, l = 0, 0, (max + min) / 2

  if max == min then
    h, s = 0, 0 -- achromatic
  else
    local d = max - min
    s = l > 0.5 and d / (2 - max - min) or d / (max + min)
    if max == r then
      h = (g - b) / d + (g < b and 6 or 0)
    elseif max == g then
      h = (b - r) / d + 2
    elseif max == b then
      h = (r - g) / d + 4
    end
    h = h / 6
  end

  return h * 360, s * 100, l * 100
end

function M.hsl_to_rgb(h, s, l)
  h, s, l = h / 360, s / 100, l / 100
  local r, g, b

  if s == 0 then
    r, g, b = l, l, l -- achromatic
  else
    local function hue_to_rgb(p, q, t)
      if t < 0 then
        t = t + 1
      end
      if t > 1 then
        t = t - 1
      end
      if t < 1 / 6 then
        return p + (q - p) * 6 * t
      end
      if t < 1 / 2 then
        return q
      end
      if t < 2 / 3 then
        return p + (q - p) * (2 / 3 - t) * 6
      end
      return p
    end

    local q = l < 0.5 and l * (1 + s) or l + s - l * s
    local p = 2 * l - q
    r = hue_to_rgb(p, q, h + 1 / 3)
    g = hue_to_rgb(p, q, h)
    b = hue_to_rgb(p, q, h - 1 / 3)
  end

  return math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5)
end

function M.hex_to_rgb(hex)
  hex = hex:gsub('#', '')
  return tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
end

function M.rgb_to_hex(r, g, b)
  return string.format('#%02x%02x%02x', r, g, b)
end

function M.adjust_brightness(hex, factor)
  local r, g, b = M.hex_to_rgb(hex)
  local h, s, l = M.rgb_to_hsl(r, g, b)
  l = math.max(0, math.min(100, l * factor))
  local nr, ng, nb = M.hsl_to_rgb(h, s, l)
  return M.rgb_to_hex(nr, ng, nb)
end

return M