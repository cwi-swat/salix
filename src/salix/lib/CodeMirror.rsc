module salix::lib::CodeMirror

import salix::HTML;
import salix::Core;
import salix::Node;
import salix::lib::Mode;
import IO;
import String;
import List;


data Hnd
  = codeMirrorChange(Handle handle)
  ;

Msg codeMirrorChangeParser(Handle h, map[str, str] p)
  = applyMaps(h, decode(h.id, #Msg(int, int, int, int, str, str))(
           toInt(p["fromLine"]), toInt(p["fromCol"]), 
           toInt(p["toLine"]), toInt(p["toCol"]),
           p["text"], p["removed"]));

void codeMirror(value vals...) = build(vals, _codeMirror);

void codeMirrorWithMode(Mode mode, value vals...) = build(vals, _codeMirrorWithMode(mode));

Node(list[Node],list[Attr]) _codeMirrorWithMode(Mode mode)
  = Node(list[Node] _, list[Attr] attrs) { 
      return native("codeMirror",  propsOf(attrs), eventsOf(attrs), extra = ("mode": mode));
   };

Node _codeMirror(list[Node] _, list[Attr] attrs)
  = native("codeMirror",  propsOf(attrs), eventsOf(attrs));

// hack to make something run on import
// NB: bug, after decl!!

void registerCodeMirror() {
  msgParser("codeMirrorChange", codeMirrorChangeParser);
}


Attr onChange(Msg(int, int, int, int, str, str) ch2msg)
  = event("change", codeMirrorChange(encode(ch2msg)));

// Special cased
// http://codemirror.net/doc/manual.html#setSize

Attr width(int px) = prop("width", "<px>");
Attr height(int px) = prop("height", "<px>");


Attr \value(str val) = prop("value", val);
Attr mode(str name) = prop("mode", name);
Attr theme(str val) = prop("theme", val);
Attr indentUnit(int val) = prop("indentUnit", "<val>");
Attr smartIndent(bool val) = prop("smartIndent", "<val>");
Attr tabSize(int val) = prop("tabSize", "<val>");
Attr indentWithTabs(bool val) = prop("indentWithTabs", "<val>");
Attr electricChars(bool val) = prop("electricChars", "<val>");
//specialChars: RegExp
Attr rtlMoveVisually(bool val) = prop("rtlMoveVisually", "<val>");
Attr keyMap(str val) = prop("keyMap", val);
//extraKeys: object
Attr lineWrapping(bool val) = prop("lineWrapping", "<val>");
Attr lineNumbers(bool val) = prop("lineNumbers", "<val>");
Attr firstLineNumber(int val) = prop("firstLineNumber", "<val>");
//lineNumberFormatter: function(Attr line(int val) = prop("line", "<val>");) → string
//gutters: array<string>
Attr fixedGutter(bool val) = prop("fixedGutter", "<val>");
Attr scrollbarStyle(str val) = prop("scrollbarStyle", val);
Attr coverGutterNextToScrollbar(bool val) = prop("coverGutterNextToScrollbar", "<val>");
Attr inputStyle(str val) = prop("inputStyle", val);
Attr readOnly(bool val) = prop("readOnly", "<val>");//|string // 'nocursor'
Attr readOnly(str val) = prop("readOnly", val);//|string // 'nocursor'
Attr showCursorWhenSelecting(bool val) = prop("showCursorWhenSelecting", "<val>");
Attr lineWiseCopyCut(bool val) = prop("lineWiseCopyCut", "<val>");
Attr undoDepth(int val) = prop("undoDepth", "<val>");
Attr historyEventDelay(int val) = prop("historyEventDelay", "<val>");
Attr tabindex(int val) = prop("tabindex", "<val>");
Attr autofocus(bool val) = prop("autofocus", "<val>");
Attr dragDrop(bool val) = prop("dragDrop", "<val>");
//allowDropFileTypes: array<string>
Attr cursorBlinkRate(int val) = prop("cursorBlinkRate", "<val>");
Attr cursorScrollMargin(int val) = prop("cursorScrollMargin", "<val>");
Attr cursorHeight(int val) = prop("cursorHeight", "<val>");
Attr resetSelectionOnContextMenu(bool val) = prop("resetSelectionOnContextMenu", "<val>");
Attr workTime(int val) = prop("workDelay", "<val>");
Attr workDelay(int val) = prop("workDelay", "<val>");
Attr pollInterval(int val) = prop("pollInterval", "<val>");
Attr flattenSpans(bool val) = prop("flattenSpans", "<val>");
Attr addModeClass(bool val) = prop("addModeClass", "<val>");
Attr maxHighlightLength(int val) = prop("maxHighlightLength", "<val>");
Attr viewportMargin(int val) = prop("viewportMargin", "<val>");