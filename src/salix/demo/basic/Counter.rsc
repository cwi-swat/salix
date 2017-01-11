@license{
  Copyright (c) 2016-2017 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Tijs van der Storm - storm@cwi.nl - CWI}

module salix::demo::basic::Counter

import salix::App;
import salix::HTML;

import String;
import IO;


alias Model = tuple[int count];

Model init() = <0>;


App[Model] counterApp()
  = app(init, view, update, |http://localhost:7000|, |project://salix/src|);

data Msg
  = inc()
  | dec()
  ;


Model update(Msg msg, Model m) {
  switch (msg) {
    case inc(): m.count += 1;
    case dec(): m.count -= 1;
  }
  return m;
}

void view(Model m) {
  div(() {
    
    h2("My first counter app in Rascal");
    
    button(onClick(inc()), "▲");
    
    div("<m.count>");
    
    button(onClick(dec()), "▼");

  });
}

