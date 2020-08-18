# interactive-gnuplot

An extremely lightweight wrapper around a Gnuplot process.

## An Example

The main entry point is the `gnuplot` macro. For example, the Gnuplot program
```
set samples 400
plot [-10:10] real(sin(x)**besj0(x))
```

can be expressed as

```
(gnuplot
  (:set :samples 400)
  (:set :title "Example" :font ",20")
  (:plot (fragment "[-10:10]") (fragment "real(sin(x)**besj0(x))")))
```


## How it Works

`interactive-gnuplot` manages a Gnuplot process. Commands, specified as Lisp strings, may be executed via `execute-command`. 

Commands themselves may be built from `gnuplot-fragment` objects, which may be concatenated to make a complete command. The generic `translate-to-fragment` has methods which convert Lisp objects into fragments, and `gnuplot-command-string` applies this to a list of objects. As an example:

```
INTERACTIVE-GNUPLOT> (translate-to-fragment :foo)
#S(GNUPLOT-FRAGMENT :STRING "foo")

INTERACTIVE-GNUPLOT> (gnuplot-command-string (list :plot (fragment "foo") :with "bar" 3))
"plot foo with \"bar\" 3"
```

The `gnuplot` macro is just a friendly wrapper over this. The above example expands to
```
(PROGN
 (EXECUTE-COMMAND (GNUPLOT-COMMAND-STRING (LIST :SET :SAMPLES 400)))
 (EXECUTE-COMMAND
  (GNUPLOT-COMMAND-STRING (LIST :SET :TITLE "Example" :FONT ",20")))
 (EXECUTE-COMMAND
  (GNUPLOT-COMMAND-STRING
   (LIST :PLOT (FRAGMENT "[-10:10]") (FRAGMENT "real(sin(x)**besj0(x))")))))
```
