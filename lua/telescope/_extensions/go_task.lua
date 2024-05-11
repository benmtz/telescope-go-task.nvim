local action_state = require("telescope.actions.state")
local actions = require("telescope.actions")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local sorters = require("telescope.sorters")
local make_entry = require("telescope.make_entry")


return require("telescope").register_extension {
  exports = {
    go_task = function(opts)
      opts = opts or {}
      opts.cwd = opts.cwd or vim.fn.getcwd()

      -- local command = {"git", "log", "--pretty=%aN <%aE>"}
      local command = {
          "sh",
          "-c",
          "task --list-all"
              .. " | sed -e '1d; s/\\* \\(.*\\):\\s*\\(.*\\)\\s*(aliases.*/\\1\\t\\2/' -e 's/\\* \\(.*\\):\\s*\\(.*\\)/\\1\\t\\2/'"
              .. " | awk '{$1= $1};1'"
      }


      local seen = {};
      local string_entry_maker = make_entry.gen_from_string()
      opts.entry_maker = function(string)
        if (not seen[string]) then
          seen[string] = true
          return string_entry_maker(string)
        else
          return nil
        end
      end

      pickers.new(opts, {
        prompt_title = 'Go task',
        finder = finders.new_oneshot_job(command, opts),
        sorter = sorters.get_generic_fuzzy_sorter(),
        attach_mappings = function(prompt_bufnr, map)

          -- We wrap the task invocation inside a higher order function 
          -- in order to be able to start it in different configurations
          local run_task_split = function(split_type, extra_args)

            extra_args = extra_args or ""

            local run_task = function()
              local task = action_state.get_selected_entry()
              actions.close(prompt_bufnr)
              vim.cmd(split_type .. [[  term://task  ]] .. task[1] .. " " .. extra_args)
            end

            return run_task
          end

          actions.select_default:replace(run_task_split("vsplit"))
          map({'i', 'n'}, '<c-v>', run_task_split("vsplit"))
          map({'i', 'n'}, '<c-x>', run_task_split("split"))
          map({'i', 'n'}, '<c-t>', run_task_split("tabnew"))
          map({'i', 'n'}, '<c-w>', run_task_split("tabnew", "-w"))

          return true
        end,
      }):find()
    end
  }
}

