module EvalInModuleREPLMode

using REPL
using REPL.LineEdit

# default module
mod_name = "Main"
mod = Main
code = ""

# initialize prompts
module_selector_mode=LineEdit.Prompt("eval in module: ")
in_module_eval_mode=LineEdit.Prompt("Main")

function reset_module()
  global mod_name, mod
  mod_name = "Main"
  mod = Main
end

function return_callback(s)
  ast = Base.parse_input_line(String(take!(copy(LineEdit.buffer(s)))))
  if  !isa(ast, Expr) || (ast.head != :continue && ast.head != :incomplete)
      return true
  else
      return false
  end
end

function __init__()
  # setup prompts
  let main_mode = Base.active_repl.interface.modes[1]
    # setup keymap of both prompts
    module_selector_mode.keymap_dict = in_module_eval_mode.keymap_dict =
      LineEdit.keymap(Dict{Any,Any}[REPL.mode_keymap(main_mode),
        LineEdit.history_keymap, LineEdit.default_keymap,
        LineEdit.escape_defaults])

    module_selector_mode.on_enter = (s) -> begin
      global mod_name
      global mod
      buf = LineEdit.buffer(s)
      let new_name = String(take!(copy(buf))), is_except=false
        if new_name != ""
          try
            mod_name = new_name
            mod = Main.eval(Symbol(mod_name))
          catch e
            reset_module()
            is_except = true
          end
        else
          LineEdit.edit_insert(s, mod_name)
        end
        if is_except || !(typeof(mod) <: Module)
          LineEdit.clear_input_area(s)
          @warn "$(mod_name) is not a valid name of a module"
          #take!(buf)
          return false
        end
        #take!(buf)
      end
      return true
    end
    module_selector_mode.on_done = (s, buf, ok) -> begin
      global mod, mod_name
      in_module_eval_mode.prompt = mod_name * "> "
      buf = LineEdit.buffer(s)
      LineEdit.transition(s, in_module_eval_mode) do
        #LineEdit.state(s, in_module_eval_mode).input_buffer = buf
      end
    end
    in_module_eval_mode.on_done = (s, buf, ok) -> begin
      global mod, code
      code *= String(take!(buf))
      ast = Base.parse_input_line(code)
      # if code is not complete
      (!isa(ast,Expr) || ast.head != :incomplete) || return
      code = ""
      mod.eval(ast)
      LineEdit.transition(s, main_mode) do
        LineEdit.state(s, main_mode).input_buffer = buf
      end
    end
    in_module_eval_mode.on_enter = return_callback

    # inject into main mode
    keymap=Dict{Any, Any}(":" =>  (s, args...) -> begin
      if isempty(s) || position(LineEdit.buffer(s)) == 0
        buf = copy(LineEdit.buffer(s))
        LineEdit.transition(s, module_selector_mode) do
          LineEdit.state(s, module_selector_mode).input_buffer = buf
        end
      else
        LineEdit.edit_insert(s, ":")
      end
    end)
    main_mode.keymap_dict = LineEdit.keymap_merge(main_mode.keymap_dict, keymap)
  end
end

end # module
