ENV["LANG"] = "C"

module TclDialogTests

using TclTk

function runtests()
    interp = TclTk.TclInterp()
    answer = TclTk.messagebox(interp; message="Really quit?", icon="question",
        type="yesno", detail="Select \"Yes\" to make the application exit")
    if answer == "yes"
        #quit()
        TclTk.messagebox(interp; message="Too bad, bye bye...", type="ok")

    elseif answer == "no"
        TclTk.messagebox(interp; message="I know you like this application!",
            type="ok")
    end
end

end # module
