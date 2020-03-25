@license{
  Copyright (c) Tijs van der Storm <Centrum Wiskunde & Informatica>.
  All rights reserved.
  This file is licensed under the BSD 2-Clause License, which accompanies this project
  and is available under https://opensource.org/licenses/BSD-2-Clause.
}
@contributor{Tijs van der Storm - storm@cwi.nl - CWI}

module salix::App

import salix::Node;
import salix::Core;
import salix::Diff;
import salix::Patch;

import util::Webserver;
import util::Reflective;
import util::Maybe;
import IO;
import String;

//private loc libRoot = getModuleLocation("salix::App").parent.parent;

data Msg;

@doc{The basic Web App type for use within Rascal:
- serve to start serving the application
- stop to shutdown the server}
//alias App[&T] = tuple[void() serve, void() stop];
alias App[&T] = Content;

@doc{SalixRequest and SalixResponse are HTTP independent types that model
the basic workflow of Salix.}
data SalixRequest
  = begin()
  | message(map[str, str] params)
  ;
  
data SalixResponse
  = next(list[Cmd] cmds, list[Sub] subs, Patch patch)
  ;
  
@doc{A function type to describe a basic SalixApp without committing to a 
particular HTTP server yet. The second argument represents the scope this
app should operate on, which is the DOM element with that string as id.
This allows using one web server to serve/multiplex different Salix apps
on a single page.}
alias SalixApp[&T] = tuple[str id, SalixResponse (SalixRequest) rr];

@doc{Construct a SalixApp over model type &T, providing a view, a model update,
and optionally a list of subscriptions, and a possibly extended parser for
handling messages originating from wrapped "native" elements.}
SalixApp[&T] makeApp(str appId, &T() init, void(&T) view, &T(Msg, &T) update, Subs[&T] subs = noSubs, Parser parser = parseMsg) {
   
  Node asRoot(Node h) = h[attrs=h.attrs + ("id": appId)];

  Node currentView = empty();
  
  Maybe[&T] currentModel = nothing();
   
  SalixResponse transition(list[Cmd] cmds, &T newModel) {

    list[Sub] mySubs = subs(appId, newModel);
    
    Node newView = asRoot(render(appId, newModel, view));
    Patch myPatch = diff(currentView, newView);

    //iprintln(myPatch);
    currentView = newView;
    currentModel = just(newModel);
    
    return next(cmds, mySubs, myPatch);
  }


  SalixResponse reply(SalixRequest req) {
    // initially, just render the view, for the initial model.
    switch (req) {
      case begin(): {
        currentView = empty();
        <cmds, model> = initialize(appId, init, view);
        return transition(cmds, model);
      } 
      case message(map[str,str] params): {
        Msg msg = params2msg(appId, params, parser);
        println("Processing: <appId>/<msg>");
        <cmds, newModel> = execute(msg, update, currentModel.val);
        return transition(cmds, newModel);
      }
      default: throw "Invalid Salix request <req>";
    }
  };
  
  return <appId, reply>;
}

App[&T] webApp(SalixApp[&T] app, loc index, loc static) = webApp(app.id, {app}, index, static);

App[&T] webApp(str id, set[SalixApp[&T]] apps, loc index, loc static) {
  mesh = webApp(id, index, static);
  for (app <- apps) {
    mesh.addApp(app);
  } 
  
  return mesh.webApp;
} 

alias SalixMesh = tuple[App[&T] webApp, void (SalixApp[&T]) addApp];

SalixMesh webApp(str id, loc index, loc static) { 
  set[SalixApp[&T]] apps = {};
  
  void add(SalixApp[&T] app) {
    apps += app;
  }
  
  Response respondHttp(SalixResponse r)
    = response(("commands": r.cmds, "subs": r.subs, "patch": r.patch));
 
  Response _handle(Request req) {
    if (get("/") := req) {
      return fileResponse(index, mimeTypes["html"], ());
    } else if (get(p:/\.<ext:[^.]*>$/) := req) {
      return fileResponse(static[path="<static.path>/<p>"], mimeTypes[ext], ());
    }
    
    list[str] path = split("/", req.path);
    str curAppId = path[1];
    
    if (SalixApp[&T] app <- apps, app.id == curAppId) {
      if (get("/<app.id>/init") := req) {
        return respondHttp(app.rr(begin()));
      } else if (get("/<app.id>/msg") := req) { 
        return respondHttp(app.rr(message(req.parameters)));
      } else { 
        return response(notFound(), "not handled: <req.path>");
      }
    } else { 
      return response(notFound(), "no salix app configured with id `<curAppId>`");
    } 
  }

  return <content(id, _handle), add>;
}