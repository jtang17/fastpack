let () =
  let time = Unix.gettimeofday () in
  let open Cmdliner in

  let run_t =

    let run
        input
        output
        mode
        target
        cache
        debug
        transpile
        postprocess
      =
      let report (m, cache, message) =
        let report () =
          Printf.sprintf
            "Packed in %.3fs. Number of modules: %d. Cache: %s. %s\n"
            (Unix.gettimeofday () -. time)
            m
            (if cache then "yes" else "no")
            message
          |> Lwt_io.write Lwt_io.stdout
        in
          Lwt_main.run (report ())
      in
      if debug then begin
        Logs.set_level (Some Logs.Debug);
        Logs.set_reporter (Logs_fmt.reporter ());
      end;
      try
        let options =
          { Fastpack.
            input;
            output;
            mode = Some mode;
            target;
            cache = Some cache;
            transpile = Some transpile;
            postprocess = Some postprocess;
          }
        in
        `Ok (Fastpack.pack_main options |> report)
      with
      | Fastpack.PackError (ctx, error) ->
        `Error (false, Fastpack.string_of_error ctx error)
    in


    let input_t =
      let doc =
        "Entry point JavaScript file"
      in
      let docv = "INPUT" in
      Arg.(value & pos 0 (some string) None & info [] ~docv ~doc)
    in

    let output_t =
      let doc =
        "Output Directory. "
        ^ "The target bundle will be $(docv)/index.js"
      in
      let docv = "DIR" in
      Arg.(value & opt (some string) None & info ["o"; "output"] ~docv ~doc)
    in

    let mode_t =
      let open Fastpack.Mode in
      let doc = "Build bundle for development" in
      let development = Development, Arg.info ["development"] ~doc in
      Arg.(value & vflag Production [development])
    in

    let target_t =
      let doc = "Deployment target." in
      let docv = "[ app | es6 | cjs ]" in
      let target =
        Arg.enum [
          "app", Fastpack.Target.Application;
          "es6", Fastpack.Target.EcmaScript6;
          "cjs", Fastpack.Target.CommonJS;
        ]
      in
      Arg.(value & opt (some target) None & info ["target"] ~docv ~doc)
    in

    let cache_t =
        let open Fastpack.Cache in
        let doc = "Do not use cache at all" in
        let ignore = Ignore, Arg.info ["no-cache"] ~doc in
        Arg.(value & vflag Normal [ignore])
    in

    let debug_t =
      let doc = "Print debug output" in
      Arg.(value & flag & info ["d"; "debug"] ~doc)
    in

    let transpile_t =
      let doc =
        "Apply transpilers to files matching $(docv) the regular expression. "
        ^ "Currently available transpilers are: stripping Flow types, "
        ^ "object spread & rest opertions, class properties (including statics), "
        ^ "class/method decorators, and React-assumed JSX conversion."
      in
      let docv = "PATTERN" in
      Arg.(value & opt_all string [] & info ["transpile"] ~docv ~doc)
    in

    let postprocess_t =
      let doc =
        "Apply shell command on a bundle file. The content of the bundle will"
        ^ " be sent to STDIN and STDOUT output will be collected. If multiple"
        ^ " commands are specified they will be applied in the order of appearance"
      in
      let docv = "COMMAND" in
      Arg.(value & opt_all string [] & info ["postprocess"] ~docv ~doc)
    in

    Term.(ret (
        const run
        $ input_t
        $ output_t
        $ mode_t
        $ target_t
        $ cache_t
        $ debug_t
        $ transpile_t
        $ postprocess_t
    ))
  in

  let info =
    let doc =
      "Pack JavaScript code into a single bundle"
    in
    let version = Fastpack.Version.(
        Printf.sprintf "%s (Commit: %s)" version github_commit
      )
    in
    Term.info "fpack" ~version ~doc ~exits:Term.default_exits
  in

  Term.exit @@ Term.eval (run_t, info)
