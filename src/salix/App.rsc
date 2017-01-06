module salix::App

import salix::Node;
import salix::Core;
import salix::Diff;
import salix::Patch;

import util::Webserver;
import IO;
import String;
import Map;
import List;

data Msg;

@doc{The basic App type:
- serve to start serving the application
- stop to shutdown the server}
alias App[&T] = tuple[void() serve, void() stop];


WithCmd[&T](Msg, &T) withoutCmd(&T(Msg, &T) update)
  = WithCmd[&T](Msg m, &T t) { return noCmd(update(m, t)); };


@doc{Helper function for apps that don't need commands.}
App[&T] app(&T() init, void(&T) view, &T(Msg, &T) update, loc http, loc static, 
            Subs[&T] subs = noSubs, str root = "root", Parser parser = parseMsg) 
 = app(WithCmd[&T]() { return noCmd(init()); }, 
    view, withoutCmd(update), http, static, subs = subs, root = root);

@doc{Construct an App over model type &T, providing a view, a model update,
a http loc to serve the app to, and a location to resolve static files.
The keyword param root identifies the root element in the html document.}
App[&T] app(WithCmd[&T]() init, void(&T) view, WithCmd[&T](Msg, &T) update, loc http, loc static, 
            Subs[&T] subs = noSubs, str root = "root", Parser parser = parseMsg) {

  Node asRoot(Node h) = h[attrs=h.attrs + ("id": root)];

  Node currentView = empty();
  
  &T currentModel;
  
  
  // TODO: we have to somehow know whether we're still responding
  // to cmd message (and hence not send any UI updates).
  // [apparently Elm does not serialize them, but runs them in parallel.
  //  I wonder if this is correct...]
  list[Cmd] pendingCommands = [];
  
  
  Response transition(&T newModel, Cmd cmd) {
    currentModel = newModel;

    list[Sub] mySubs = subs(newModel);
    
    Node newView = asRoot(render(newModel, view));
    Patch myPatch = diff(currentView, newView);

    currentView = newView;
    
    return response([cmd, mySubs, myPatch]);
  }

  // the main handler to interpret http requests.
  // BUG: mixes with constructors that are in scope!!!
  Response _handle(Request req) {
    
    // initially, just render the view, for the current model.
    if (get("/init") := req) {
      currentView = empty();
      <model, myCmd> = initialize(init, view);
      return transition(model, myCmd);
    }
    
    
    // if receiving an (encoded) message
    if (get("/msg") := req) {
      //println("Parsing request");
      Msg msg = params2msg(req.parameters, parser);
      println("Processing: <msg>");
      <newModel, myCmd> = update(msg, currentModel);
      return transition(newModel, myCmd);
    }
    
    // everything else is considered static files.
    if (get(p:/\.<ext:[^.]*>$/) := req, ext in mimeTypes) {
      return fileResponse(static[path="<static.path>/<p>"], mimeTypes[ext], ());
    }
    
    // or not found
    return response(notFound(), "not handled: <req.path>");
  }

  return <
    () { println("Serving at: <http>"); serve(http, _handle); }, 
    () { shutdown(http); }
   >;
}

