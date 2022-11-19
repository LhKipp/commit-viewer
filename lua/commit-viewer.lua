local M = {}
local v = vim

local log = require 'commit-viewer.log'

function M._run_git_log(additional_args)
    log.info("Calling _run_git_log")
    local util = require('commit-viewer.util')

    -- Collect args
    local args = { 'log', '--color=never', '--date=short', '--format=%cd %h%d %s (%an)' }
    vim.list_extend(args, additional_args)

    return util.run_git_cmd(args)
end

local bufname = "Git Log"
function M._get_buffer()
    local buf = nil
    if M._config.reuse_buffer then
        for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
            if string.find(vim.api.nvim_buf_get_name(bufnr), bufname) ~= nil then
                buf = bufnr
                log.info("Found existing buffer. Reusing it")
                break
            end
        end
    end
    if buf == nil then
        buf = vim.api.nvim_create_buf(true, true)
        if buf == 0 then
            v.api.nvim_err_writeln("Couldn't create a new buffer!")
            return nil
        end
        if M._config.reuse_buffer then -- name has to be unique, so only set the name, when reusing the buffer
            vim.api.nvim_buf_set_name(buf, "Git Log")
        end
        log.info("Created new buffer")
    end

    -- In case the buffer was only unlisted, reset the ft
    vim.api.nvim_buf_set_option(buf, 'filetype', 'CV')

    return buf
end

function M.open(args)
    local buf = M._get_buffer()
    if buf == nil then
        return
    end

    local log_lines = M._run_git_log(args)
    if log_lines == nil then
        return
    end
    M._last_executed_args = args
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, log_lines)
    vim.api.nvim_win_set_buf(0, buf)
end

function M.redraw()
    log.info("Redrawing with ", vim.inspect(M._last_executed_args))
    M.open(M._last_executed_args)
end

-- Configuration --

local function default_opts()
    return {
        reuse_buffer = false
    }
end

function M.setup(opts)
    M._config = vim.tbl_extend("force", default_opts(), opts)

    vim.api.nvim_create_user_command("CV", function(args)
        if args.bang then
            vim.list_extend(args.fargs, { '--', vim.fn.expand("%:p") })
        end
        M.open(args.fargs)
    end, { bang = true, complete = "file", nargs = "*" })
end

return M