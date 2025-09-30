-- Utility functions for nvim configuration

local M = {}

-- Show highlight groups under cursor (modern Treesitter + legacy fallback)
function M.show_highlight_groups()
  local line = vim.fn.line '.'
  local col = vim.fn.col '.'

  -- Get Treesitter highlights
  local ts_highlights = vim.treesitter.get_captures_at_cursor(0)

  -- If treesitter highlights exist, use :Inspect for detailed info
  if #ts_highlights > 0 then
    print 'Treesitter highlights found. Using :Inspect for detailed information...'
    vim.cmd 'Inspect'
    return
  end

  -- Get legacy syntax highlights (fallback)
  local syn_id = vim.fn.synID(line, col, 1)
  local syn_name = vim.fn.synIDattr(syn_id, 'name')

  -- Combine results
  local groups = {}

  -- Add legacy syntax if available
  if syn_name ~= '' then
    table.insert(groups, syn_name)
  end

  if #groups == 0 then
    print 'No highlight groups found'
    return
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

-- Open markdown link under cursor
function M.open_markdown_link()
  local line = vim.fn.getline '.'
  local col = vim.fn.col '.'

  -- First, try to find markdown link pattern [content](url) around cursor
  local link_pattern = '%[([^%]]+)%]%(([^%)]+)%)'
  local start_pos = 1

  while true do
    local content_start, content_end, _content, url = string.find(line, link_pattern, start_pos)
    if not content_start then
      break
    end

    -- Check if cursor is within this link
    if col >= content_start and col <= content_end then
      -- Found the link under cursor, process the URL
      local converted_url = vim.fn['knot#ConvertIdLink'](url)

      if converted_url == '' then
        -- Empty result, do nothing
        return
      elseif string.match(converted_url, '^https?://') then
        -- It's a URL, open with xdg-open
        vim.fn.ReloadEnvironment()
        vim.fn.system('xdg-open "' .. converted_url .. '"')
      else
        -- It's a relative path, handle anchors
        local file_path = converted_url
        local anchor = nil

        -- Check for anchor (#something)
        local anchor_pos = string.find(file_path, '#')
        if anchor_pos then
          anchor = string.sub(file_path, anchor_pos + 1)
          file_path = string.sub(file_path, 1, anchor_pos - 1)
        end

        -- Open the file
        vim.cmd('edit ' .. vim.fn.fnameescape(file_path))

        -- if anchor then
        -- TODO: Implement anchor seeking to find heading with this text
        -- end
        -- print('Opening file: ' .. file_path)
      end
      return
    end

    start_pos = content_end + 1
  end

  -- If no markdown link found, try to find plain HTTP/HTTPS URLs around cursor
  local url_pattern = "(https?://[%w%-._~:/?#%[%]@!$&'%(%)%*%+,;=%%]+)"
  start_pos = 1

  while true do
    local url_start, url_end, url = string.find(line, url_pattern, start_pos)
    if not url_start then
      break
    end

    -- Check if cursor is within this URL
    if col >= url_start and col <= url_end then
      -- Found a plain URL under cursor, open it
      vim.fn.ReloadEnvironment()
      vim.fn.system('xdg-open "' .. url .. '"')
      return
    end

    start_pos = url_end + 1
  end

  print 'No link or URL found under cursor'
end

-- Show Vim key notation for the next key pressed
-- NOTE: Native Neovim methods to identify keys:
--   1. In insert mode: <C-v> then press your key combination
--   2. Command mode: :<C-v> then press your key combination
--   3. Check mappings: :map <key> or :verbose map <key>
--   4. Help: :help key-notation or :help i_<key>
function M.show_key_notation()
  print 'Press any key combination to see its Vim notation...'
  local key = vim.fn.getchar()
  local key_name = vim.fn.keytrans(vim.fn.nr2char(key))
  print(string.format('Vim key notation: %s', key_name))
end

return M
