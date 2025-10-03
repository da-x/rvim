--- @class blink.cmp.Source
--- @field new fun(ctx: blink.cmp.Context): blink.cmp.Source
local Source = {}

function Source.new()
  local self = setmetatable({}, { __index = Source })
  return self
end

function Source:get_completions(context, callback)
  local completions = {}
  
  -- Check if UltiSnips is available
  if not vim.fn.exists('*UltiSnips#SnippetsInCurrentScope') then
    callback({ items = {} })
    return
  end
  
  -- Get snippets from UltiSnips
  local snippets = vim.fn['UltiSnips#SnippetsInCurrentScope'](1)
  
  for trigger, description in pairs(snippets) do
    table.insert(completions, {
      label = trigger,
      kind = vim.lsp.protocol.CompletionItemKind.Snippet,
      detail = description,
      documentation = {
        kind = 'markdown',
        value = string.format('**UltiSnips snippet**\n\n%s', description)
      },
      insertText = trigger,
      insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText,
      command = {
        title = 'Expand UltiSnips',
        command = 'ultisnips.expand',
        arguments = { trigger }
      },
      data = {
        source = 'ultisnips',
        trigger = trigger
      }
    })
  end
  
  callback({ items = completions })
end

function Source:resolve(item, callback)
  -- For UltiSnips, we don't need additional resolution
  if type(callback) == 'function' then
    callback(item)
  elseif type(callback) == 'table' and callback.callback then
    callback.callback(item)
  end
end

function Source:execute(item, callback)
  -- Trigger UltiSnips expansion using tab key simulation
  if item.data and item.data.trigger then
    vim.schedule(function()
      -- Clear the line and insert the trigger
      vim.cmd('normal! diw')
      vim.api.nvim_put({item.data.trigger}, 'c', true, true)
      -- Trigger expansion with tab
      vim.fn.feedkeys('\t', 'n')
    end)
  end
  
  -- Handle callback properly - it might be a table with a function
  if type(callback) == 'function' then
    callback()
  elseif type(callback) == 'table' and callback.callback then
    callback.callback()
  end
end

function Source:get_trigger_characters()
  return {}
end

function Source:should_show_items(ctx)
  return true
end

return Source