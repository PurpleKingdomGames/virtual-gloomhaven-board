(function(scope){
'use strict';

function F(arity, fun, wrapper) {
  wrapper.a = arity;
  wrapper.f = fun;
  return wrapper;
}

function F2(fun) {
  return F(2, fun, function(a) { return function(b) { return fun(a,b); }; })
}
function F3(fun) {
  return F(3, fun, function(a) {
    return function(b) { return function(c) { return fun(a, b, c); }; };
  });
}
function F4(fun) {
  return F(4, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return fun(a, b, c, d); }; }; };
  });
}
function F5(fun) {
  return F(5, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return fun(a, b, c, d, e); }; }; }; };
  });
}
function F6(fun) {
  return F(6, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return fun(a, b, c, d, e, f); }; }; }; }; };
  });
}
function F7(fun) {
  return F(7, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return function(g) { return fun(a, b, c, d, e, f, g); }; }; }; }; }; };
  });
}
function F8(fun) {
  return F(8, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return function(g) { return function(h) {
    return fun(a, b, c, d, e, f, g, h); }; }; }; }; }; }; };
  });
}
function F9(fun) {
  return F(9, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return function(g) { return function(h) { return function(i) {
    return fun(a, b, c, d, e, f, g, h, i); }; }; }; }; }; }; }; };
  });
}

function A2(fun, a, b) {
  return fun.a === 2 ? fun.f(a, b) : fun(a)(b);
}
function A3(fun, a, b, c) {
  return fun.a === 3 ? fun.f(a, b, c) : fun(a)(b)(c);
}
function A4(fun, a, b, c, d) {
  return fun.a === 4 ? fun.f(a, b, c, d) : fun(a)(b)(c)(d);
}
function A5(fun, a, b, c, d, e) {
  return fun.a === 5 ? fun.f(a, b, c, d, e) : fun(a)(b)(c)(d)(e);
}
function A6(fun, a, b, c, d, e, f) {
  return fun.a === 6 ? fun.f(a, b, c, d, e, f) : fun(a)(b)(c)(d)(e)(f);
}
function A7(fun, a, b, c, d, e, f, g) {
  return fun.a === 7 ? fun.f(a, b, c, d, e, f, g) : fun(a)(b)(c)(d)(e)(f)(g);
}
function A8(fun, a, b, c, d, e, f, g, h) {
  return fun.a === 8 ? fun.f(a, b, c, d, e, f, g, h) : fun(a)(b)(c)(d)(e)(f)(g)(h);
}
function A9(fun, a, b, c, d, e, f, g, h, i) {
  return fun.a === 9 ? fun.f(a, b, c, d, e, f, g, h, i) : fun(a)(b)(c)(d)(e)(f)(g)(h)(i);
}




// EQUALITY

function _Utils_eq(x, y)
{
	for (
		var pair, stack = [], isEqual = _Utils_eqHelp(x, y, 0, stack);
		isEqual && (pair = stack.pop());
		isEqual = _Utils_eqHelp(pair.a, pair.b, 0, stack)
		)
	{}

	return isEqual;
}

function _Utils_eqHelp(x, y, depth, stack)
{
	if (x === y)
	{
		return true;
	}

	if (typeof x !== 'object' || x === null || y === null)
	{
		typeof x === 'function' && _Debug_crash(5);
		return false;
	}

	if (depth > 100)
	{
		stack.push(_Utils_Tuple2(x,y));
		return true;
	}

	/**_UNUSED/
	if (x.$ === 'Set_elm_builtin')
	{
		x = $elm$core$Set$toList(x);
		y = $elm$core$Set$toList(y);
	}
	if (x.$ === 'RBNode_elm_builtin' || x.$ === 'RBEmpty_elm_builtin')
	{
		x = $elm$core$Dict$toList(x);
		y = $elm$core$Dict$toList(y);
	}
	//*/

	/**/
	if (x.$ < 0)
	{
		x = $elm$core$Dict$toList(x);
		y = $elm$core$Dict$toList(y);
	}
	//*/

	for (var key in x)
	{
		if (!_Utils_eqHelp(x[key], y[key], depth + 1, stack))
		{
			return false;
		}
	}
	return true;
}

var _Utils_equal = F2(_Utils_eq);
var _Utils_notEqual = F2(function(a, b) { return !_Utils_eq(a,b); });



// COMPARISONS

// Code in Generate/JavaScript.hs, Basics.js, and List.js depends on
// the particular integer values assigned to LT, EQ, and GT.

function _Utils_cmp(x, y, ord)
{
	if (typeof x !== 'object')
	{
		return x === y ? /*EQ*/ 0 : x < y ? /*LT*/ -1 : /*GT*/ 1;
	}

	/**_UNUSED/
	if (x instanceof String)
	{
		var a = x.valueOf();
		var b = y.valueOf();
		return a === b ? 0 : a < b ? -1 : 1;
	}
	//*/

	/**/
	if (typeof x.$ === 'undefined')
	//*/
	/**_UNUSED/
	if (x.$[0] === '#')
	//*/
	{
		return (ord = _Utils_cmp(x.a, y.a))
			? ord
			: (ord = _Utils_cmp(x.b, y.b))
				? ord
				: _Utils_cmp(x.c, y.c);
	}

	// traverse conses until end of a list or a mismatch
	for (; x.b && y.b && !(ord = _Utils_cmp(x.a, y.a)); x = x.b, y = y.b) {} // WHILE_CONSES
	return ord || (x.b ? /*GT*/ 1 : y.b ? /*LT*/ -1 : /*EQ*/ 0);
}

var _Utils_lt = F2(function(a, b) { return _Utils_cmp(a, b) < 0; });
var _Utils_le = F2(function(a, b) { return _Utils_cmp(a, b) < 1; });
var _Utils_gt = F2(function(a, b) { return _Utils_cmp(a, b) > 0; });
var _Utils_ge = F2(function(a, b) { return _Utils_cmp(a, b) >= 0; });

var _Utils_compare = F2(function(x, y)
{
	var n = _Utils_cmp(x, y);
	return n < 0 ? $elm$core$Basics$LT : n ? $elm$core$Basics$GT : $elm$core$Basics$EQ;
});


// COMMON VALUES

var _Utils_Tuple0 = 0;
var _Utils_Tuple0_UNUSED = { $: '#0' };

function _Utils_Tuple2(a, b) { return { a: a, b: b }; }
function _Utils_Tuple2_UNUSED(a, b) { return { $: '#2', a: a, b: b }; }

function _Utils_Tuple3(a, b, c) { return { a: a, b: b, c: c }; }
function _Utils_Tuple3_UNUSED(a, b, c) { return { $: '#3', a: a, b: b, c: c }; }

function _Utils_chr(c) { return c; }
function _Utils_chr_UNUSED(c) { return new String(c); }


// RECORDS

function _Utils_update(oldRecord, updatedFields)
{
	var newRecord = {};

	for (var key in oldRecord)
	{
		newRecord[key] = oldRecord[key];
	}

	for (var key in updatedFields)
	{
		newRecord[key] = updatedFields[key];
	}

	return newRecord;
}


// APPEND

var _Utils_append = F2(_Utils_ap);

function _Utils_ap(xs, ys)
{
	// append Strings
	if (typeof xs === 'string')
	{
		return xs + ys;
	}

	// append Lists
	if (!xs.b)
	{
		return ys;
	}
	var root = _List_Cons(xs.a, ys);
	xs = xs.b
	for (var curr = root; xs.b; xs = xs.b) // WHILE_CONS
	{
		curr = curr.b = _List_Cons(xs.a, ys);
	}
	return root;
}



var _List_Nil = { $: 0 };
var _List_Nil_UNUSED = { $: '[]' };

function _List_Cons(hd, tl) { return { $: 1, a: hd, b: tl }; }
function _List_Cons_UNUSED(hd, tl) { return { $: '::', a: hd, b: tl }; }


var _List_cons = F2(_List_Cons);

function _List_fromArray(arr)
{
	var out = _List_Nil;
	for (var i = arr.length; i--; )
	{
		out = _List_Cons(arr[i], out);
	}
	return out;
}

function _List_toArray(xs)
{
	for (var out = []; xs.b; xs = xs.b) // WHILE_CONS
	{
		out.push(xs.a);
	}
	return out;
}

var _List_map2 = F3(function(f, xs, ys)
{
	for (var arr = []; xs.b && ys.b; xs = xs.b, ys = ys.b) // WHILE_CONSES
	{
		arr.push(A2(f, xs.a, ys.a));
	}
	return _List_fromArray(arr);
});

var _List_map3 = F4(function(f, xs, ys, zs)
{
	for (var arr = []; xs.b && ys.b && zs.b; xs = xs.b, ys = ys.b, zs = zs.b) // WHILE_CONSES
	{
		arr.push(A3(f, xs.a, ys.a, zs.a));
	}
	return _List_fromArray(arr);
});

var _List_map4 = F5(function(f, ws, xs, ys, zs)
{
	for (var arr = []; ws.b && xs.b && ys.b && zs.b; ws = ws.b, xs = xs.b, ys = ys.b, zs = zs.b) // WHILE_CONSES
	{
		arr.push(A4(f, ws.a, xs.a, ys.a, zs.a));
	}
	return _List_fromArray(arr);
});

var _List_map5 = F6(function(f, vs, ws, xs, ys, zs)
{
	for (var arr = []; vs.b && ws.b && xs.b && ys.b && zs.b; vs = vs.b, ws = ws.b, xs = xs.b, ys = ys.b, zs = zs.b) // WHILE_CONSES
	{
		arr.push(A5(f, vs.a, ws.a, xs.a, ys.a, zs.a));
	}
	return _List_fromArray(arr);
});

var _List_sortBy = F2(function(f, xs)
{
	return _List_fromArray(_List_toArray(xs).sort(function(a, b) {
		return _Utils_cmp(f(a), f(b));
	}));
});

var _List_sortWith = F2(function(f, xs)
{
	return _List_fromArray(_List_toArray(xs).sort(function(a, b) {
		var ord = A2(f, a, b);
		return ord === $elm$core$Basics$EQ ? 0 : ord === $elm$core$Basics$LT ? -1 : 1;
	}));
});



var _JsArray_empty = [];

function _JsArray_singleton(value)
{
    return [value];
}

function _JsArray_length(array)
{
    return array.length;
}

var _JsArray_initialize = F3(function(size, offset, func)
{
    var result = new Array(size);

    for (var i = 0; i < size; i++)
    {
        result[i] = func(offset + i);
    }

    return result;
});

var _JsArray_initializeFromList = F2(function (max, ls)
{
    var result = new Array(max);

    for (var i = 0; i < max && ls.b; i++)
    {
        result[i] = ls.a;
        ls = ls.b;
    }

    result.length = i;
    return _Utils_Tuple2(result, ls);
});

var _JsArray_unsafeGet = F2(function(index, array)
{
    return array[index];
});

var _JsArray_unsafeSet = F3(function(index, value, array)
{
    var length = array.length;
    var result = new Array(length);

    for (var i = 0; i < length; i++)
    {
        result[i] = array[i];
    }

    result[index] = value;
    return result;
});

var _JsArray_push = F2(function(value, array)
{
    var length = array.length;
    var result = new Array(length + 1);

    for (var i = 0; i < length; i++)
    {
        result[i] = array[i];
    }

    result[length] = value;
    return result;
});

var _JsArray_foldl = F3(function(func, acc, array)
{
    var length = array.length;

    for (var i = 0; i < length; i++)
    {
        acc = A2(func, array[i], acc);
    }

    return acc;
});

var _JsArray_foldr = F3(function(func, acc, array)
{
    for (var i = array.length - 1; i >= 0; i--)
    {
        acc = A2(func, array[i], acc);
    }

    return acc;
});

var _JsArray_map = F2(function(func, array)
{
    var length = array.length;
    var result = new Array(length);

    for (var i = 0; i < length; i++)
    {
        result[i] = func(array[i]);
    }

    return result;
});

var _JsArray_indexedMap = F3(function(func, offset, array)
{
    var length = array.length;
    var result = new Array(length);

    for (var i = 0; i < length; i++)
    {
        result[i] = A2(func, offset + i, array[i]);
    }

    return result;
});

var _JsArray_slice = F3(function(from, to, array)
{
    return array.slice(from, to);
});

var _JsArray_appendN = F3(function(n, dest, source)
{
    var destLen = dest.length;
    var itemsToCopy = n - destLen;

    if (itemsToCopy > source.length)
    {
        itemsToCopy = source.length;
    }

    var size = destLen + itemsToCopy;
    var result = new Array(size);

    for (var i = 0; i < destLen; i++)
    {
        result[i] = dest[i];
    }

    for (var i = 0; i < itemsToCopy; i++)
    {
        result[i + destLen] = source[i];
    }

    return result;
});



// LOG

var _Debug_log = F2(function(tag, value)
{
	return value;
});

var _Debug_log_UNUSED = F2(function(tag, value)
{
	console.log(tag + ': ' + _Debug_toString(value));
	return value;
});


// TODOS

function _Debug_todo(moduleName, region)
{
	return function(message) {
		_Debug_crash(8, moduleName, region, message);
	};
}

function _Debug_todoCase(moduleName, region, value)
{
	return function(message) {
		_Debug_crash(9, moduleName, region, value, message);
	};
}


// TO STRING

function _Debug_toString(value)
{
	return '<internals>';
}

function _Debug_toString_UNUSED(value)
{
	return _Debug_toAnsiString(false, value);
}

function _Debug_toAnsiString(ansi, value)
{
	if (typeof value === 'function')
	{
		return _Debug_internalColor(ansi, '<function>');
	}

	if (typeof value === 'boolean')
	{
		return _Debug_ctorColor(ansi, value ? 'True' : 'False');
	}

	if (typeof value === 'number')
	{
		return _Debug_numberColor(ansi, value + '');
	}

	if (value instanceof String)
	{
		return _Debug_charColor(ansi, "'" + _Debug_addSlashes(value, true) + "'");
	}

	if (typeof value === 'string')
	{
		return _Debug_stringColor(ansi, '"' + _Debug_addSlashes(value, false) + '"');
	}

	if (typeof value === 'object' && '$' in value)
	{
		var tag = value.$;

		if (typeof tag === 'number')
		{
			return _Debug_internalColor(ansi, '<internals>');
		}

		if (tag[0] === '#')
		{
			var output = [];
			for (var k in value)
			{
				if (k === '$') continue;
				output.push(_Debug_toAnsiString(ansi, value[k]));
			}
			return '(' + output.join(',') + ')';
		}

		if (tag === 'Set_elm_builtin')
		{
			return _Debug_ctorColor(ansi, 'Set')
				+ _Debug_fadeColor(ansi, '.fromList') + ' '
				+ _Debug_toAnsiString(ansi, $elm$core$Set$toList(value));
		}

		if (tag === 'RBNode_elm_builtin' || tag === 'RBEmpty_elm_builtin')
		{
			return _Debug_ctorColor(ansi, 'Dict')
				+ _Debug_fadeColor(ansi, '.fromList') + ' '
				+ _Debug_toAnsiString(ansi, $elm$core$Dict$toList(value));
		}

		if (tag === 'Array_elm_builtin')
		{
			return _Debug_ctorColor(ansi, 'Array')
				+ _Debug_fadeColor(ansi, '.fromList') + ' '
				+ _Debug_toAnsiString(ansi, $elm$core$Array$toList(value));
		}

		if (tag === '::' || tag === '[]')
		{
			var output = '[';

			value.b && (output += _Debug_toAnsiString(ansi, value.a), value = value.b)

			for (; value.b; value = value.b) // WHILE_CONS
			{
				output += ',' + _Debug_toAnsiString(ansi, value.a);
			}
			return output + ']';
		}

		var output = '';
		for (var i in value)
		{
			if (i === '$') continue;
			var str = _Debug_toAnsiString(ansi, value[i]);
			var c0 = str[0];
			var parenless = c0 === '{' || c0 === '(' || c0 === '[' || c0 === '<' || c0 === '"' || str.indexOf(' ') < 0;
			output += ' ' + (parenless ? str : '(' + str + ')');
		}
		return _Debug_ctorColor(ansi, tag) + output;
	}

	if (typeof DataView === 'function' && value instanceof DataView)
	{
		return _Debug_stringColor(ansi, '<' + value.byteLength + ' bytes>');
	}

	if (typeof File !== 'undefined' && value instanceof File)
	{
		return _Debug_internalColor(ansi, '<' + value.name + '>');
	}

	if (typeof value === 'object')
	{
		var output = [];
		for (var key in value)
		{
			var field = key[0] === '_' ? key.slice(1) : key;
			output.push(_Debug_fadeColor(ansi, field) + ' = ' + _Debug_toAnsiString(ansi, value[key]));
		}
		if (output.length === 0)
		{
			return '{}';
		}
		return '{ ' + output.join(', ') + ' }';
	}

	return _Debug_internalColor(ansi, '<internals>');
}

function _Debug_addSlashes(str, isChar)
{
	var s = str
		.replace(/\\/g, '\\\\')
		.replace(/\n/g, '\\n')
		.replace(/\t/g, '\\t')
		.replace(/\r/g, '\\r')
		.replace(/\v/g, '\\v')
		.replace(/\0/g, '\\0');

	if (isChar)
	{
		return s.replace(/\'/g, '\\\'');
	}
	else
	{
		return s.replace(/\"/g, '\\"');
	}
}

function _Debug_ctorColor(ansi, string)
{
	return ansi ? '\x1b[96m' + string + '\x1b[0m' : string;
}

function _Debug_numberColor(ansi, string)
{
	return ansi ? '\x1b[95m' + string + '\x1b[0m' : string;
}

function _Debug_stringColor(ansi, string)
{
	return ansi ? '\x1b[93m' + string + '\x1b[0m' : string;
}

function _Debug_charColor(ansi, string)
{
	return ansi ? '\x1b[92m' + string + '\x1b[0m' : string;
}

function _Debug_fadeColor(ansi, string)
{
	return ansi ? '\x1b[37m' + string + '\x1b[0m' : string;
}

function _Debug_internalColor(ansi, string)
{
	return ansi ? '\x1b[36m' + string + '\x1b[0m' : string;
}

function _Debug_toHexDigit(n)
{
	return String.fromCharCode(n < 10 ? 48 + n : 55 + n);
}


// CRASH


function _Debug_crash(identifier)
{
	throw new Error('https://github.com/elm/core/blob/1.0.0/hints/' + identifier + '.md');
}


function _Debug_crash_UNUSED(identifier, fact1, fact2, fact3, fact4)
{
	switch(identifier)
	{
		case 0:
			throw new Error('What node should I take over? In JavaScript I need something like:\n\n    Elm.Main.init({\n        node: document.getElementById("elm-node")\n    })\n\nYou need to do this with any Browser.sandbox or Browser.element program.');

		case 1:
			throw new Error('Browser.application programs cannot handle URLs like this:\n\n    ' + document.location.href + '\n\nWhat is the root? The root of your file system? Try looking at this program with `elm reactor` or some other server.');

		case 2:
			var jsonErrorString = fact1;
			throw new Error('Problem with the flags given to your Elm program on initialization.\n\n' + jsonErrorString);

		case 3:
			var portName = fact1;
			throw new Error('There can only be one port named `' + portName + '`, but your program has multiple.');

		case 4:
			var portName = fact1;
			var problem = fact2;
			throw new Error('Trying to send an unexpected type of value through port `' + portName + '`:\n' + problem);

		case 5:
			throw new Error('Trying to use `(==)` on functions.\nThere is no way to know if functions are "the same" in the Elm sense.\nRead more about this at https://package.elm-lang.org/packages/elm/core/latest/Basics#== which describes why it is this way and what the better version will look like.');

		case 6:
			var moduleName = fact1;
			throw new Error('Your page is loading multiple Elm scripts with a module named ' + moduleName + '. Maybe a duplicate script is getting loaded accidentally? If not, rename one of them so I know which is which!');

		case 8:
			var moduleName = fact1;
			var region = fact2;
			var message = fact3;
			throw new Error('TODO in module `' + moduleName + '` ' + _Debug_regionToString(region) + '\n\n' + message);

		case 9:
			var moduleName = fact1;
			var region = fact2;
			var value = fact3;
			var message = fact4;
			throw new Error(
				'TODO in module `' + moduleName + '` from the `case` expression '
				+ _Debug_regionToString(region) + '\n\nIt received the following value:\n\n    '
				+ _Debug_toString(value).replace('\n', '\n    ')
				+ '\n\nBut the branch that handles it says:\n\n    ' + message.replace('\n', '\n    ')
			);

		case 10:
			throw new Error('Bug in https://github.com/elm/virtual-dom/issues');

		case 11:
			throw new Error('Cannot perform mod 0. Division by zero error.');
	}
}

function _Debug_regionToString(region)
{
	if (region.aJ.T === region.a4.T)
	{
		return 'on line ' + region.aJ.T;
	}
	return 'on lines ' + region.aJ.T + ' through ' + region.a4.T;
}



// MATH

var _Basics_add = F2(function(a, b) { return a + b; });
var _Basics_sub = F2(function(a, b) { return a - b; });
var _Basics_mul = F2(function(a, b) { return a * b; });
var _Basics_fdiv = F2(function(a, b) { return a / b; });
var _Basics_idiv = F2(function(a, b) { return (a / b) | 0; });
var _Basics_pow = F2(Math.pow);

var _Basics_remainderBy = F2(function(b, a) { return a % b; });

// https://www.microsoft.com/en-us/research/wp-content/uploads/2016/02/divmodnote-letter.pdf
var _Basics_modBy = F2(function(modulus, x)
{
	var answer = x % modulus;
	return modulus === 0
		? _Debug_crash(11)
		:
	((answer > 0 && modulus < 0) || (answer < 0 && modulus > 0))
		? answer + modulus
		: answer;
});


// TRIGONOMETRY

var _Basics_pi = Math.PI;
var _Basics_e = Math.E;
var _Basics_cos = Math.cos;
var _Basics_sin = Math.sin;
var _Basics_tan = Math.tan;
var _Basics_acos = Math.acos;
var _Basics_asin = Math.asin;
var _Basics_atan = Math.atan;
var _Basics_atan2 = F2(Math.atan2);


// MORE MATH

function _Basics_toFloat(x) { return x; }
function _Basics_truncate(n) { return n | 0; }
function _Basics_isInfinite(n) { return n === Infinity || n === -Infinity; }

var _Basics_ceiling = Math.ceil;
var _Basics_floor = Math.floor;
var _Basics_round = Math.round;
var _Basics_sqrt = Math.sqrt;
var _Basics_log = Math.log;
var _Basics_isNaN = isNaN;


// BOOLEANS

function _Basics_not(bool) { return !bool; }
var _Basics_and = F2(function(a, b) { return a && b; });
var _Basics_or  = F2(function(a, b) { return a || b; });
var _Basics_xor = F2(function(a, b) { return a !== b; });



var _String_cons = F2(function(chr, str)
{
	return chr + str;
});

function _String_uncons(string)
{
	var word = string.charCodeAt(0);
	return !isNaN(word)
		? $elm$core$Maybe$Just(
			0xD800 <= word && word <= 0xDBFF
				? _Utils_Tuple2(_Utils_chr(string[0] + string[1]), string.slice(2))
				: _Utils_Tuple2(_Utils_chr(string[0]), string.slice(1))
		)
		: $elm$core$Maybe$Nothing;
}

var _String_append = F2(function(a, b)
{
	return a + b;
});

function _String_length(str)
{
	return str.length;
}

var _String_map = F2(function(func, string)
{
	var len = string.length;
	var array = new Array(len);
	var i = 0;
	while (i < len)
	{
		var word = string.charCodeAt(i);
		if (0xD800 <= word && word <= 0xDBFF)
		{
			array[i] = func(_Utils_chr(string[i] + string[i+1]));
			i += 2;
			continue;
		}
		array[i] = func(_Utils_chr(string[i]));
		i++;
	}
	return array.join('');
});

var _String_filter = F2(function(isGood, str)
{
	var arr = [];
	var len = str.length;
	var i = 0;
	while (i < len)
	{
		var char = str[i];
		var word = str.charCodeAt(i);
		i++;
		if (0xD800 <= word && word <= 0xDBFF)
		{
			char += str[i];
			i++;
		}

		if (isGood(_Utils_chr(char)))
		{
			arr.push(char);
		}
	}
	return arr.join('');
});

function _String_reverse(str)
{
	var len = str.length;
	var arr = new Array(len);
	var i = 0;
	while (i < len)
	{
		var word = str.charCodeAt(i);
		if (0xD800 <= word && word <= 0xDBFF)
		{
			arr[len - i] = str[i + 1];
			i++;
			arr[len - i] = str[i - 1];
			i++;
		}
		else
		{
			arr[len - i] = str[i];
			i++;
		}
	}
	return arr.join('');
}

var _String_foldl = F3(function(func, state, string)
{
	var len = string.length;
	var i = 0;
	while (i < len)
	{
		var char = string[i];
		var word = string.charCodeAt(i);
		i++;
		if (0xD800 <= word && word <= 0xDBFF)
		{
			char += string[i];
			i++;
		}
		state = A2(func, _Utils_chr(char), state);
	}
	return state;
});

var _String_foldr = F3(function(func, state, string)
{
	var i = string.length;
	while (i--)
	{
		var char = string[i];
		var word = string.charCodeAt(i);
		if (0xDC00 <= word && word <= 0xDFFF)
		{
			i--;
			char = string[i] + char;
		}
		state = A2(func, _Utils_chr(char), state);
	}
	return state;
});

var _String_split = F2(function(sep, str)
{
	return str.split(sep);
});

var _String_join = F2(function(sep, strs)
{
	return strs.join(sep);
});

var _String_slice = F3(function(start, end, str) {
	return str.slice(start, end);
});

function _String_trim(str)
{
	return str.trim();
}

function _String_trimLeft(str)
{
	return str.replace(/^\s+/, '');
}

function _String_trimRight(str)
{
	return str.replace(/\s+$/, '');
}

function _String_words(str)
{
	return _List_fromArray(str.trim().split(/\s+/g));
}

function _String_lines(str)
{
	return _List_fromArray(str.split(/\r\n|\r|\n/g));
}

function _String_toUpper(str)
{
	return str.toUpperCase();
}

function _String_toLower(str)
{
	return str.toLowerCase();
}

var _String_any = F2(function(isGood, string)
{
	var i = string.length;
	while (i--)
	{
		var char = string[i];
		var word = string.charCodeAt(i);
		if (0xDC00 <= word && word <= 0xDFFF)
		{
			i--;
			char = string[i] + char;
		}
		if (isGood(_Utils_chr(char)))
		{
			return true;
		}
	}
	return false;
});

var _String_all = F2(function(isGood, string)
{
	var i = string.length;
	while (i--)
	{
		var char = string[i];
		var word = string.charCodeAt(i);
		if (0xDC00 <= word && word <= 0xDFFF)
		{
			i--;
			char = string[i] + char;
		}
		if (!isGood(_Utils_chr(char)))
		{
			return false;
		}
	}
	return true;
});

var _String_contains = F2(function(sub, str)
{
	return str.indexOf(sub) > -1;
});

var _String_startsWith = F2(function(sub, str)
{
	return str.indexOf(sub) === 0;
});

var _String_endsWith = F2(function(sub, str)
{
	return str.length >= sub.length &&
		str.lastIndexOf(sub) === str.length - sub.length;
});

var _String_indexes = F2(function(sub, str)
{
	var subLen = sub.length;

	if (subLen < 1)
	{
		return _List_Nil;
	}

	var i = 0;
	var is = [];

	while ((i = str.indexOf(sub, i)) > -1)
	{
		is.push(i);
		i = i + subLen;
	}

	return _List_fromArray(is);
});


// TO STRING

function _String_fromNumber(number)
{
	return number + '';
}


// INT CONVERSIONS

function _String_toInt(str)
{
	var total = 0;
	var code0 = str.charCodeAt(0);
	var start = code0 == 0x2B /* + */ || code0 == 0x2D /* - */ ? 1 : 0;

	for (var i = start; i < str.length; ++i)
	{
		var code = str.charCodeAt(i);
		if (code < 0x30 || 0x39 < code)
		{
			return $elm$core$Maybe$Nothing;
		}
		total = 10 * total + code - 0x30;
	}

	return i == start
		? $elm$core$Maybe$Nothing
		: $elm$core$Maybe$Just(code0 == 0x2D ? -total : total);
}


// FLOAT CONVERSIONS

function _String_toFloat(s)
{
	// check if it is a hex, octal, or binary number
	if (s.length === 0 || /[\sxbo]/.test(s))
	{
		return $elm$core$Maybe$Nothing;
	}
	var n = +s;
	// faster isNaN check
	return n === n ? $elm$core$Maybe$Just(n) : $elm$core$Maybe$Nothing;
}

function _String_fromList(chars)
{
	return _List_toArray(chars).join('');
}




function _Char_toCode(char)
{
	var code = char.charCodeAt(0);
	if (0xD800 <= code && code <= 0xDBFF)
	{
		return (code - 0xD800) * 0x400 + char.charCodeAt(1) - 0xDC00 + 0x10000
	}
	return code;
}

function _Char_fromCode(code)
{
	return _Utils_chr(
		(code < 0 || 0x10FFFF < code)
			? '\uFFFD'
			:
		(code <= 0xFFFF)
			? String.fromCharCode(code)
			:
		(code -= 0x10000,
			String.fromCharCode(Math.floor(code / 0x400) + 0xD800, code % 0x400 + 0xDC00)
		)
	);
}

function _Char_toUpper(char)
{
	return _Utils_chr(char.toUpperCase());
}

function _Char_toLower(char)
{
	return _Utils_chr(char.toLowerCase());
}

function _Char_toLocaleUpper(char)
{
	return _Utils_chr(char.toLocaleUpperCase());
}

function _Char_toLocaleLower(char)
{
	return _Utils_chr(char.toLocaleLowerCase());
}



/**_UNUSED/
function _Json_errorToString(error)
{
	return $elm$json$Json$Decode$errorToString(error);
}
//*/


// CORE DECODERS

function _Json_succeed(msg)
{
	return {
		$: 0,
		a: msg
	};
}

function _Json_fail(msg)
{
	return {
		$: 1,
		a: msg
	};
}

function _Json_decodePrim(decoder)
{
	return { $: 2, b: decoder };
}

var _Json_decodeInt = _Json_decodePrim(function(value) {
	return (typeof value !== 'number')
		? _Json_expecting('an INT', value)
		:
	(-2147483647 < value && value < 2147483647 && (value | 0) === value)
		? $elm$core$Result$Ok(value)
		:
	(isFinite(value) && !(value % 1))
		? $elm$core$Result$Ok(value)
		: _Json_expecting('an INT', value);
});

var _Json_decodeBool = _Json_decodePrim(function(value) {
	return (typeof value === 'boolean')
		? $elm$core$Result$Ok(value)
		: _Json_expecting('a BOOL', value);
});

var _Json_decodeFloat = _Json_decodePrim(function(value) {
	return (typeof value === 'number')
		? $elm$core$Result$Ok(value)
		: _Json_expecting('a FLOAT', value);
});

var _Json_decodeValue = _Json_decodePrim(function(value) {
	return $elm$core$Result$Ok(_Json_wrap(value));
});

var _Json_decodeString = _Json_decodePrim(function(value) {
	return (typeof value === 'string')
		? $elm$core$Result$Ok(value)
		: (value instanceof String)
			? $elm$core$Result$Ok(value + '')
			: _Json_expecting('a STRING', value);
});

function _Json_decodeList(decoder) { return { $: 3, b: decoder }; }
function _Json_decodeArray(decoder) { return { $: 4, b: decoder }; }

function _Json_decodeNull(value) { return { $: 5, c: value }; }

var _Json_decodeField = F2(function(field, decoder)
{
	return {
		$: 6,
		d: field,
		b: decoder
	};
});

var _Json_decodeIndex = F2(function(index, decoder)
{
	return {
		$: 7,
		e: index,
		b: decoder
	};
});

function _Json_decodeKeyValuePairs(decoder)
{
	return {
		$: 8,
		b: decoder
	};
}

function _Json_mapMany(f, decoders)
{
	return {
		$: 9,
		f: f,
		g: decoders
	};
}

var _Json_andThen = F2(function(callback, decoder)
{
	return {
		$: 10,
		b: decoder,
		h: callback
	};
});

function _Json_oneOf(decoders)
{
	return {
		$: 11,
		g: decoders
	};
}


// DECODING OBJECTS

var _Json_map1 = F2(function(f, d1)
{
	return _Json_mapMany(f, [d1]);
});

var _Json_map2 = F3(function(f, d1, d2)
{
	return _Json_mapMany(f, [d1, d2]);
});

var _Json_map3 = F4(function(f, d1, d2, d3)
{
	return _Json_mapMany(f, [d1, d2, d3]);
});

var _Json_map4 = F5(function(f, d1, d2, d3, d4)
{
	return _Json_mapMany(f, [d1, d2, d3, d4]);
});

var _Json_map5 = F6(function(f, d1, d2, d3, d4, d5)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5]);
});

var _Json_map6 = F7(function(f, d1, d2, d3, d4, d5, d6)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5, d6]);
});

var _Json_map7 = F8(function(f, d1, d2, d3, d4, d5, d6, d7)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5, d6, d7]);
});

var _Json_map8 = F9(function(f, d1, d2, d3, d4, d5, d6, d7, d8)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5, d6, d7, d8]);
});


// DECODE

var _Json_runOnString = F2(function(decoder, string)
{
	try
	{
		var value = JSON.parse(string);
		return _Json_runHelp(decoder, value);
	}
	catch (e)
	{
		return $elm$core$Result$Err(A2($elm$json$Json$Decode$Failure, 'This is not valid JSON! ' + e.message, _Json_wrap(string)));
	}
});

var _Json_run = F2(function(decoder, value)
{
	return _Json_runHelp(decoder, _Json_unwrap(value));
});

function _Json_runHelp(decoder, value)
{
	switch (decoder.$)
	{
		case 2:
			return decoder.b(value);

		case 5:
			return (value === null)
				? $elm$core$Result$Ok(decoder.c)
				: _Json_expecting('null', value);

		case 3:
			if (!_Json_isArray(value))
			{
				return _Json_expecting('a LIST', value);
			}
			return _Json_runArrayDecoder(decoder.b, value, _List_fromArray);

		case 4:
			if (!_Json_isArray(value))
			{
				return _Json_expecting('an ARRAY', value);
			}
			return _Json_runArrayDecoder(decoder.b, value, _Json_toElmArray);

		case 6:
			var field = decoder.d;
			if (typeof value !== 'object' || value === null || !(field in value))
			{
				return _Json_expecting('an OBJECT with a field named `' + field + '`', value);
			}
			var result = _Json_runHelp(decoder.b, value[field]);
			return ($elm$core$Result$isOk(result)) ? result : $elm$core$Result$Err(A2($elm$json$Json$Decode$Field, field, result.a));

		case 7:
			var index = decoder.e;
			if (!_Json_isArray(value))
			{
				return _Json_expecting('an ARRAY', value);
			}
			if (index >= value.length)
			{
				return _Json_expecting('a LONGER array. Need index ' + index + ' but only see ' + value.length + ' entries', value);
			}
			var result = _Json_runHelp(decoder.b, value[index]);
			return ($elm$core$Result$isOk(result)) ? result : $elm$core$Result$Err(A2($elm$json$Json$Decode$Index, index, result.a));

		case 8:
			if (typeof value !== 'object' || value === null || _Json_isArray(value))
			{
				return _Json_expecting('an OBJECT', value);
			}

			var keyValuePairs = _List_Nil;
			// TODO test perf of Object.keys and switch when support is good enough
			for (var key in value)
			{
				if (value.hasOwnProperty(key))
				{
					var result = _Json_runHelp(decoder.b, value[key]);
					if (!$elm$core$Result$isOk(result))
					{
						return $elm$core$Result$Err(A2($elm$json$Json$Decode$Field, key, result.a));
					}
					keyValuePairs = _List_Cons(_Utils_Tuple2(key, result.a), keyValuePairs);
				}
			}
			return $elm$core$Result$Ok($elm$core$List$reverse(keyValuePairs));

		case 9:
			var answer = decoder.f;
			var decoders = decoder.g;
			for (var i = 0; i < decoders.length; i++)
			{
				var result = _Json_runHelp(decoders[i], value);
				if (!$elm$core$Result$isOk(result))
				{
					return result;
				}
				answer = answer(result.a);
			}
			return $elm$core$Result$Ok(answer);

		case 10:
			var result = _Json_runHelp(decoder.b, value);
			return (!$elm$core$Result$isOk(result))
				? result
				: _Json_runHelp(decoder.h(result.a), value);

		case 11:
			var errors = _List_Nil;
			for (var temp = decoder.g; temp.b; temp = temp.b) // WHILE_CONS
			{
				var result = _Json_runHelp(temp.a, value);
				if ($elm$core$Result$isOk(result))
				{
					return result;
				}
				errors = _List_Cons(result.a, errors);
			}
			return $elm$core$Result$Err($elm$json$Json$Decode$OneOf($elm$core$List$reverse(errors)));

		case 1:
			return $elm$core$Result$Err(A2($elm$json$Json$Decode$Failure, decoder.a, _Json_wrap(value)));

		case 0:
			return $elm$core$Result$Ok(decoder.a);
	}
}

function _Json_runArrayDecoder(decoder, value, toElmValue)
{
	var len = value.length;
	var array = new Array(len);
	for (var i = 0; i < len; i++)
	{
		var result = _Json_runHelp(decoder, value[i]);
		if (!$elm$core$Result$isOk(result))
		{
			return $elm$core$Result$Err(A2($elm$json$Json$Decode$Index, i, result.a));
		}
		array[i] = result.a;
	}
	return $elm$core$Result$Ok(toElmValue(array));
}

function _Json_isArray(value)
{
	return Array.isArray(value) || (typeof FileList !== 'undefined' && value instanceof FileList);
}

function _Json_toElmArray(array)
{
	return A2($elm$core$Array$initialize, array.length, function(i) { return array[i]; });
}

function _Json_expecting(type, value)
{
	return $elm$core$Result$Err(A2($elm$json$Json$Decode$Failure, 'Expecting ' + type, _Json_wrap(value)));
}


// EQUALITY

function _Json_equality(x, y)
{
	if (x === y)
	{
		return true;
	}

	if (x.$ !== y.$)
	{
		return false;
	}

	switch (x.$)
	{
		case 0:
		case 1:
			return x.a === y.a;

		case 2:
			return x.b === y.b;

		case 5:
			return x.c === y.c;

		case 3:
		case 4:
		case 8:
			return _Json_equality(x.b, y.b);

		case 6:
			return x.d === y.d && _Json_equality(x.b, y.b);

		case 7:
			return x.e === y.e && _Json_equality(x.b, y.b);

		case 9:
			return x.f === y.f && _Json_listEquality(x.g, y.g);

		case 10:
			return x.h === y.h && _Json_equality(x.b, y.b);

		case 11:
			return _Json_listEquality(x.g, y.g);
	}
}

function _Json_listEquality(aDecoders, bDecoders)
{
	var len = aDecoders.length;
	if (len !== bDecoders.length)
	{
		return false;
	}
	for (var i = 0; i < len; i++)
	{
		if (!_Json_equality(aDecoders[i], bDecoders[i]))
		{
			return false;
		}
	}
	return true;
}


// ENCODE

var _Json_encode = F2(function(indentLevel, value)
{
	return JSON.stringify(_Json_unwrap(value), null, indentLevel) + '';
});

function _Json_wrap_UNUSED(value) { return { $: 0, a: value }; }
function _Json_unwrap_UNUSED(value) { return value.a; }

function _Json_wrap(value) { return value; }
function _Json_unwrap(value) { return value; }

function _Json_emptyArray() { return []; }
function _Json_emptyObject() { return {}; }

var _Json_addField = F3(function(key, value, object)
{
	object[key] = _Json_unwrap(value);
	return object;
});

function _Json_addEntry(func)
{
	return F2(function(entry, array)
	{
		array.push(_Json_unwrap(func(entry)));
		return array;
	});
}

var _Json_encodeNull = _Json_wrap(null);



// TASKS

function _Scheduler_succeed(value)
{
	return {
		$: 0,
		a: value
	};
}

function _Scheduler_fail(error)
{
	return {
		$: 1,
		a: error
	};
}

function _Scheduler_binding(callback)
{
	return {
		$: 2,
		b: callback,
		c: null
	};
}

var _Scheduler_andThen = F2(function(callback, task)
{
	return {
		$: 3,
		b: callback,
		d: task
	};
});

var _Scheduler_onError = F2(function(callback, task)
{
	return {
		$: 4,
		b: callback,
		d: task
	};
});

function _Scheduler_receive(callback)
{
	return {
		$: 5,
		b: callback
	};
}


// PROCESSES

var _Scheduler_guid = 0;

function _Scheduler_rawSpawn(task)
{
	var proc = {
		$: 0,
		e: _Scheduler_guid++,
		f: task,
		g: null,
		h: []
	};

	_Scheduler_enqueue(proc);

	return proc;
}

function _Scheduler_spawn(task)
{
	return _Scheduler_binding(function(callback) {
		callback(_Scheduler_succeed(_Scheduler_rawSpawn(task)));
	});
}

function _Scheduler_rawSend(proc, msg)
{
	proc.h.push(msg);
	_Scheduler_enqueue(proc);
}

var _Scheduler_send = F2(function(proc, msg)
{
	return _Scheduler_binding(function(callback) {
		_Scheduler_rawSend(proc, msg);
		callback(_Scheduler_succeed(_Utils_Tuple0));
	});
});

function _Scheduler_kill(proc)
{
	return _Scheduler_binding(function(callback) {
		var task = proc.f;
		if (task.$ === 2 && task.c)
		{
			task.c();
		}

		proc.f = null;

		callback(_Scheduler_succeed(_Utils_Tuple0));
	});
}


/* STEP PROCESSES

type alias Process =
  { $ : tag
  , id : unique_id
  , root : Task
  , stack : null | { $: SUCCEED | FAIL, a: callback, b: stack }
  , mailbox : [msg]
  }

*/


var _Scheduler_working = false;
var _Scheduler_queue = [];


function _Scheduler_enqueue(proc)
{
	_Scheduler_queue.push(proc);
	if (_Scheduler_working)
	{
		return;
	}
	_Scheduler_working = true;
	while (proc = _Scheduler_queue.shift())
	{
		_Scheduler_step(proc);
	}
	_Scheduler_working = false;
}


function _Scheduler_step(proc)
{
	while (proc.f)
	{
		var rootTag = proc.f.$;
		if (rootTag === 0 || rootTag === 1)
		{
			while (proc.g && proc.g.$ !== rootTag)
			{
				proc.g = proc.g.i;
			}
			if (!proc.g)
			{
				return;
			}
			proc.f = proc.g.b(proc.f.a);
			proc.g = proc.g.i;
		}
		else if (rootTag === 2)
		{
			proc.f.c = proc.f.b(function(newRoot) {
				proc.f = newRoot;
				_Scheduler_enqueue(proc);
			});
			return;
		}
		else if (rootTag === 5)
		{
			if (proc.h.length === 0)
			{
				return;
			}
			proc.f = proc.f.b(proc.h.shift());
		}
		else // if (rootTag === 3 || rootTag === 4)
		{
			proc.g = {
				$: rootTag === 3 ? 0 : 1,
				b: proc.f.b,
				i: proc.g
			};
			proc.f = proc.f.d;
		}
	}
}



function _Process_sleep(time)
{
	return _Scheduler_binding(function(callback) {
		var id = setTimeout(function() {
			callback(_Scheduler_succeed(_Utils_Tuple0));
		}, time);

		return function() { clearTimeout(id); };
	});
}




// PROGRAMS


var _Platform_worker = F4(function(impl, flagDecoder, debugMetadata, args)
{
	return _Platform_initialize(
		flagDecoder,
		args,
		impl.cS,
		impl.dN,
		impl.dB,
		function() { return function() {} }
	);
});



// INITIALIZE A PROGRAM


function _Platform_initialize(flagDecoder, args, init, update, subscriptions, stepperBuilder)
{
	var result = A2(_Json_run, flagDecoder, _Json_wrap(args ? args['flags'] : undefined));
	$elm$core$Result$isOk(result) || _Debug_crash(2 /**_UNUSED/, _Json_errorToString(result.a) /**/);
	var managers = {};
	var initPair = init(result.a);
	var model = initPair.a;
	var stepper = stepperBuilder(sendToApp, model);
	var ports = _Platform_setupEffects(managers, sendToApp);

	function sendToApp(msg, viewMetadata)
	{
		var pair = A2(update, msg, model);
		stepper(model = pair.a, viewMetadata);
		_Platform_enqueueEffects(managers, pair.b, subscriptions(model));
	}

	_Platform_enqueueEffects(managers, initPair.b, subscriptions(model));

	return ports ? { ports: ports } : {};
}



// TRACK PRELOADS
//
// This is used by code in elm/browser and elm/http
// to register any HTTP requests that are triggered by init.
//


var _Platform_preload;


function _Platform_registerPreload(url)
{
	_Platform_preload.add(url);
}



// EFFECT MANAGERS


var _Platform_effectManagers = {};


function _Platform_setupEffects(managers, sendToApp)
{
	var ports;

	// setup all necessary effect managers
	for (var key in _Platform_effectManagers)
	{
		var manager = _Platform_effectManagers[key];

		if (manager.a)
		{
			ports = ports || {};
			ports[key] = manager.a(key, sendToApp);
		}

		managers[key] = _Platform_instantiateManager(manager, sendToApp);
	}

	return ports;
}


function _Platform_createManager(init, onEffects, onSelfMsg, cmdMap, subMap)
{
	return {
		b: init,
		c: onEffects,
		d: onSelfMsg,
		e: cmdMap,
		f: subMap
	};
}


function _Platform_instantiateManager(info, sendToApp)
{
	var router = {
		g: sendToApp,
		h: undefined
	};

	var onEffects = info.c;
	var onSelfMsg = info.d;
	var cmdMap = info.e;
	var subMap = info.f;

	function loop(state)
	{
		return A2(_Scheduler_andThen, loop, _Scheduler_receive(function(msg)
		{
			var value = msg.a;

			if (msg.$ === 0)
			{
				return A3(onSelfMsg, router, value, state);
			}

			return cmdMap && subMap
				? A4(onEffects, router, value.i, value.j, state)
				: A3(onEffects, router, cmdMap ? value.i : value.j, state);
		}));
	}

	return router.h = _Scheduler_rawSpawn(A2(_Scheduler_andThen, loop, info.b));
}



// ROUTING


var _Platform_sendToApp = F2(function(router, msg)
{
	return _Scheduler_binding(function(callback)
	{
		router.g(msg);
		callback(_Scheduler_succeed(_Utils_Tuple0));
	});
});


var _Platform_sendToSelf = F2(function(router, msg)
{
	return A2(_Scheduler_send, router.h, {
		$: 0,
		a: msg
	});
});



// BAGS


function _Platform_leaf(home)
{
	return function(value)
	{
		return {
			$: 1,
			k: home,
			l: value
		};
	};
}


function _Platform_batch(list)
{
	return {
		$: 2,
		m: list
	};
}


var _Platform_map = F2(function(tagger, bag)
{
	return {
		$: 3,
		n: tagger,
		o: bag
	}
});



// PIPE BAGS INTO EFFECT MANAGERS
//
// Effects must be queued!
//
// Say your init contains a synchronous command, like Time.now or Time.here
//
//   - This will produce a batch of effects (FX_1)
//   - The synchronous task triggers the subsequent `update` call
//   - This will produce a batch of effects (FX_2)
//
// If we just start dispatching FX_2, subscriptions from FX_2 can be processed
// before subscriptions from FX_1. No good! Earlier versions of this code had
// this problem, leading to these reports:
//
//   https://github.com/elm/core/issues/980
//   https://github.com/elm/core/pull/981
//   https://github.com/elm/compiler/issues/1776
//
// The queue is necessary to avoid ordering issues for synchronous commands.


// Why use true/false here? Why not just check the length of the queue?
// The goal is to detect "are we currently dispatching effects?" If we
// are, we need to bail and let the ongoing while loop handle things.
//
// Now say the queue has 1 element. When we dequeue the final element,
// the queue will be empty, but we are still actively dispatching effects.
// So you could get queue jumping in a really tricky category of cases.
//
var _Platform_effectsQueue = [];
var _Platform_effectsActive = false;


function _Platform_enqueueEffects(managers, cmdBag, subBag)
{
	_Platform_effectsQueue.push({ p: managers, q: cmdBag, r: subBag });

	if (_Platform_effectsActive) return;

	_Platform_effectsActive = true;
	for (var fx; fx = _Platform_effectsQueue.shift(); )
	{
		_Platform_dispatchEffects(fx.p, fx.q, fx.r);
	}
	_Platform_effectsActive = false;
}


function _Platform_dispatchEffects(managers, cmdBag, subBag)
{
	var effectsDict = {};
	_Platform_gatherEffects(true, cmdBag, effectsDict, null);
	_Platform_gatherEffects(false, subBag, effectsDict, null);

	for (var home in managers)
	{
		_Scheduler_rawSend(managers[home], {
			$: 'fx',
			a: effectsDict[home] || { i: _List_Nil, j: _List_Nil }
		});
	}
}


function _Platform_gatherEffects(isCmd, bag, effectsDict, taggers)
{
	switch (bag.$)
	{
		case 1:
			var home = bag.k;
			var effect = _Platform_toEffect(isCmd, home, taggers, bag.l);
			effectsDict[home] = _Platform_insert(isCmd, effect, effectsDict[home]);
			return;

		case 2:
			for (var list = bag.m; list.b; list = list.b) // WHILE_CONS
			{
				_Platform_gatherEffects(isCmd, list.a, effectsDict, taggers);
			}
			return;

		case 3:
			_Platform_gatherEffects(isCmd, bag.o, effectsDict, {
				s: bag.n,
				t: taggers
			});
			return;
	}
}


function _Platform_toEffect(isCmd, home, taggers, value)
{
	function applyTaggers(x)
	{
		for (var temp = taggers; temp; temp = temp.t)
		{
			x = temp.s(x);
		}
		return x;
	}

	var map = isCmd
		? _Platform_effectManagers[home].e
		: _Platform_effectManagers[home].f;

	return A2(map, applyTaggers, value)
}


function _Platform_insert(isCmd, newEffect, effects)
{
	effects = effects || { i: _List_Nil, j: _List_Nil };

	isCmd
		? (effects.i = _List_Cons(newEffect, effects.i))
		: (effects.j = _List_Cons(newEffect, effects.j));

	return effects;
}



// PORTS


function _Platform_checkPortName(name)
{
	if (_Platform_effectManagers[name])
	{
		_Debug_crash(3, name)
	}
}



// OUTGOING PORTS


function _Platform_outgoingPort(name, converter)
{
	_Platform_checkPortName(name);
	_Platform_effectManagers[name] = {
		e: _Platform_outgoingPortMap,
		u: converter,
		a: _Platform_setupOutgoingPort
	};
	return _Platform_leaf(name);
}


var _Platform_outgoingPortMap = F2(function(tagger, value) { return value; });


function _Platform_setupOutgoingPort(name)
{
	var subs = [];
	var converter = _Platform_effectManagers[name].u;

	// CREATE MANAGER

	var init = _Process_sleep(0);

	_Platform_effectManagers[name].b = init;
	_Platform_effectManagers[name].c = F3(function(router, cmdList, state)
	{
		for ( ; cmdList.b; cmdList = cmdList.b) // WHILE_CONS
		{
			// grab a separate reference to subs in case unsubscribe is called
			var currentSubs = subs;
			var value = _Json_unwrap(converter(cmdList.a));
			for (var i = 0; i < currentSubs.length; i++)
			{
				currentSubs[i](value);
			}
		}
		return init;
	});

	// PUBLIC API

	function subscribe(callback)
	{
		subs.push(callback);
	}

	function unsubscribe(callback)
	{
		// copy subs into a new array in case unsubscribe is called within a
		// subscribed callback
		subs = subs.slice();
		var index = subs.indexOf(callback);
		if (index >= 0)
		{
			subs.splice(index, 1);
		}
	}

	return {
		subscribe: subscribe,
		unsubscribe: unsubscribe
	};
}



// INCOMING PORTS


function _Platform_incomingPort(name, converter)
{
	_Platform_checkPortName(name);
	_Platform_effectManagers[name] = {
		f: _Platform_incomingPortMap,
		u: converter,
		a: _Platform_setupIncomingPort
	};
	return _Platform_leaf(name);
}


var _Platform_incomingPortMap = F2(function(tagger, finalTagger)
{
	return function(value)
	{
		return tagger(finalTagger(value));
	};
});


function _Platform_setupIncomingPort(name, sendToApp)
{
	var subs = _List_Nil;
	var converter = _Platform_effectManagers[name].u;

	// CREATE MANAGER

	var init = _Scheduler_succeed(null);

	_Platform_effectManagers[name].b = init;
	_Platform_effectManagers[name].c = F3(function(router, subList, state)
	{
		subs = subList;
		return init;
	});

	// PUBLIC API

	function send(incomingValue)
	{
		var result = A2(_Json_run, converter, _Json_wrap(incomingValue));

		$elm$core$Result$isOk(result) || _Debug_crash(4, name, result.a);

		var value = result.a;
		for (var temp = subs; temp.b; temp = temp.b) // WHILE_CONS
		{
			sendToApp(temp.a(value));
		}
	}

	return { send: send };
}



// EXPORT ELM MODULES
//
// Have DEBUG and PROD versions so that we can (1) give nicer errors in
// debug mode and (2) not pay for the bits needed for that in prod mode.
//


function _Platform_export(exports)
{
	scope['Elm']
		? _Platform_mergeExportsProd(scope['Elm'], exports)
		: scope['Elm'] = exports;
}


function _Platform_mergeExportsProd(obj, exports)
{
	for (var name in exports)
	{
		(name in obj)
			? (name == 'init')
				? _Debug_crash(6)
				: _Platform_mergeExportsProd(obj[name], exports[name])
			: (obj[name] = exports[name]);
	}
}


function _Platform_export_UNUSED(exports)
{
	scope['Elm']
		? _Platform_mergeExportsDebug('Elm', scope['Elm'], exports)
		: scope['Elm'] = exports;
}


function _Platform_mergeExportsDebug(moduleName, obj, exports)
{
	for (var name in exports)
	{
		(name in obj)
			? (name == 'init')
				? _Debug_crash(6, moduleName)
				: _Platform_mergeExportsDebug(moduleName + '.' + name, obj[name], exports[name])
			: (obj[name] = exports[name]);
	}
}




// HELPERS


var _VirtualDom_divertHrefToApp;

var _VirtualDom_doc = typeof document !== 'undefined' ? document : {};


function _VirtualDom_appendChild(parent, child)
{
	parent.appendChild(child);
}

var _VirtualDom_init = F4(function(virtualNode, flagDecoder, debugMetadata, args)
{
	// NOTE: this function needs _Platform_export available to work

	/**/
	var node = args['node'];
	//*/
	/**_UNUSED/
	var node = args && args['node'] ? args['node'] : _Debug_crash(0);
	//*/

	node.parentNode.replaceChild(
		_VirtualDom_render(virtualNode, function() {}),
		node
	);

	return {};
});



// TEXT


function _VirtualDom_text(string)
{
	return {
		$: 0,
		a: string
	};
}



// NODE


var _VirtualDom_nodeNS = F2(function(namespace, tag)
{
	return F2(function(factList, kidList)
	{
		for (var kids = [], descendantsCount = 0; kidList.b; kidList = kidList.b) // WHILE_CONS
		{
			var kid = kidList.a;
			descendantsCount += (kid.b || 0);
			kids.push(kid);
		}
		descendantsCount += kids.length;

		return {
			$: 1,
			c: tag,
			d: _VirtualDom_organizeFacts(factList),
			e: kids,
			f: namespace,
			b: descendantsCount
		};
	});
});


var _VirtualDom_node = _VirtualDom_nodeNS(undefined);



// KEYED NODE


var _VirtualDom_keyedNodeNS = F2(function(namespace, tag)
{
	return F2(function(factList, kidList)
	{
		for (var kids = [], descendantsCount = 0; kidList.b; kidList = kidList.b) // WHILE_CONS
		{
			var kid = kidList.a;
			descendantsCount += (kid.b.b || 0);
			kids.push(kid);
		}
		descendantsCount += kids.length;

		return {
			$: 2,
			c: tag,
			d: _VirtualDom_organizeFacts(factList),
			e: kids,
			f: namespace,
			b: descendantsCount
		};
	});
});


var _VirtualDom_keyedNode = _VirtualDom_keyedNodeNS(undefined);



// CUSTOM


function _VirtualDom_custom(factList, model, render, diff)
{
	return {
		$: 3,
		d: _VirtualDom_organizeFacts(factList),
		g: model,
		h: render,
		i: diff
	};
}



// MAP


var _VirtualDom_map = F2(function(tagger, node)
{
	return {
		$: 4,
		j: tagger,
		k: node,
		b: 1 + (node.b || 0)
	};
});



// LAZY


function _VirtualDom_thunk(refs, thunk)
{
	return {
		$: 5,
		l: refs,
		m: thunk,
		k: undefined
	};
}

var _VirtualDom_lazy = F2(function(func, a)
{
	return _VirtualDom_thunk([func, a], function() {
		return func(a);
	});
});

var _VirtualDom_lazy2 = F3(function(func, a, b)
{
	return _VirtualDom_thunk([func, a, b], function() {
		return A2(func, a, b);
	});
});

var _VirtualDom_lazy3 = F4(function(func, a, b, c)
{
	return _VirtualDom_thunk([func, a, b, c], function() {
		return A3(func, a, b, c);
	});
});

var _VirtualDom_lazy4 = F5(function(func, a, b, c, d)
{
	return _VirtualDom_thunk([func, a, b, c, d], function() {
		return A4(func, a, b, c, d);
	});
});

var _VirtualDom_lazy5 = F6(function(func, a, b, c, d, e)
{
	return _VirtualDom_thunk([func, a, b, c, d, e], function() {
		return A5(func, a, b, c, d, e);
	});
});

var _VirtualDom_lazy6 = F7(function(func, a, b, c, d, e, f)
{
	return _VirtualDom_thunk([func, a, b, c, d, e, f], function() {
		return A6(func, a, b, c, d, e, f);
	});
});

var _VirtualDom_lazy7 = F8(function(func, a, b, c, d, e, f, g)
{
	return _VirtualDom_thunk([func, a, b, c, d, e, f, g], function() {
		return A7(func, a, b, c, d, e, f, g);
	});
});

var _VirtualDom_lazy8 = F9(function(func, a, b, c, d, e, f, g, h)
{
	return _VirtualDom_thunk([func, a, b, c, d, e, f, g, h], function() {
		return A8(func, a, b, c, d, e, f, g, h);
	});
});



// FACTS


var _VirtualDom_on = F2(function(key, handler)
{
	return {
		$: 'a0',
		n: key,
		o: handler
	};
});
var _VirtualDom_style = F2(function(key, value)
{
	return {
		$: 'a1',
		n: key,
		o: value
	};
});
var _VirtualDom_property = F2(function(key, value)
{
	return {
		$: 'a2',
		n: key,
		o: value
	};
});
var _VirtualDom_attribute = F2(function(key, value)
{
	return {
		$: 'a3',
		n: key,
		o: value
	};
});
var _VirtualDom_attributeNS = F3(function(namespace, key, value)
{
	return {
		$: 'a4',
		n: key,
		o: { f: namespace, o: value }
	};
});



// XSS ATTACK VECTOR CHECKS


function _VirtualDom_noScript(tag)
{
	return tag == 'script' ? 'p' : tag;
}

function _VirtualDom_noOnOrFormAction(key)
{
	return /^(on|formAction$)/i.test(key) ? 'data-' + key : key;
}

function _VirtualDom_noInnerHtmlOrFormAction(key)
{
	return key == 'innerHTML' || key == 'formAction' ? 'data-' + key : key;
}

function _VirtualDom_noJavaScriptUri(value)
{
	return /^javascript:/i.test(value.replace(/\s/g,'')) ? '' : value;
}

function _VirtualDom_noJavaScriptUri_UNUSED(value)
{
	return /^javascript:/i.test(value.replace(/\s/g,''))
		? 'javascript:alert("This is an XSS vector. Please use ports or web components instead.")'
		: value;
}

function _VirtualDom_noJavaScriptOrHtmlUri(value)
{
	return /^\s*(javascript:|data:text\/html)/i.test(value) ? '' : value;
}

function _VirtualDom_noJavaScriptOrHtmlUri_UNUSED(value)
{
	return /^\s*(javascript:|data:text\/html)/i.test(value)
		? 'javascript:alert("This is an XSS vector. Please use ports or web components instead.")'
		: value;
}



// MAP FACTS


var _VirtualDom_mapAttribute = F2(function(func, attr)
{
	return (attr.$ === 'a0')
		? A2(_VirtualDom_on, attr.n, _VirtualDom_mapHandler(func, attr.o))
		: attr;
});

function _VirtualDom_mapHandler(func, handler)
{
	var tag = $elm$virtual_dom$VirtualDom$toHandlerInt(handler);

	// 0 = Normal
	// 1 = MayStopPropagation
	// 2 = MayPreventDefault
	// 3 = Custom

	return {
		$: handler.$,
		a:
			!tag
				? A2($elm$json$Json$Decode$map, func, handler.a)
				:
			A3($elm$json$Json$Decode$map2,
				tag < 3
					? _VirtualDom_mapEventTuple
					: _VirtualDom_mapEventRecord,
				$elm$json$Json$Decode$succeed(func),
				handler.a
			)
	};
}

var _VirtualDom_mapEventTuple = F2(function(func, tuple)
{
	return _Utils_Tuple2(func(tuple.a), tuple.b);
});

var _VirtualDom_mapEventRecord = F2(function(func, record)
{
	return {
		c1: func(record.c1),
		dA: record.dA,
		dr: record.dr
	}
});



// ORGANIZE FACTS


function _VirtualDom_organizeFacts(factList)
{
	for (var facts = {}; factList.b; factList = factList.b) // WHILE_CONS
	{
		var entry = factList.a;

		var tag = entry.$;
		var key = entry.n;
		var value = entry.o;

		if (tag === 'a2')
		{
			(key === 'className')
				? _VirtualDom_addClass(facts, key, _Json_unwrap(value))
				: facts[key] = _Json_unwrap(value);

			continue;
		}

		var subFacts = facts[tag] || (facts[tag] = {});
		(tag === 'a3' && key === 'class')
			? _VirtualDom_addClass(subFacts, key, value)
			: subFacts[key] = value;
	}

	return facts;
}

function _VirtualDom_addClass(object, key, newClass)
{
	var classes = object[key];
	object[key] = classes ? classes + ' ' + newClass : newClass;
}



// RENDER


function _VirtualDom_render(vNode, eventNode)
{
	var tag = vNode.$;

	if (tag === 5)
	{
		return _VirtualDom_render(vNode.k || (vNode.k = vNode.m()), eventNode);
	}

	if (tag === 0)
	{
		return _VirtualDom_doc.createTextNode(vNode.a);
	}

	if (tag === 4)
	{
		var subNode = vNode.k;
		var tagger = vNode.j;

		while (subNode.$ === 4)
		{
			typeof tagger !== 'object'
				? tagger = [tagger, subNode.j]
				: tagger.push(subNode.j);

			subNode = subNode.k;
		}

		var subEventRoot = { j: tagger, p: eventNode };
		var domNode = _VirtualDom_render(subNode, subEventRoot);
		domNode.elm_event_node_ref = subEventRoot;
		return domNode;
	}

	if (tag === 3)
	{
		var domNode = vNode.h(vNode.g);
		_VirtualDom_applyFacts(domNode, eventNode, vNode.d);
		return domNode;
	}

	// at this point `tag` must be 1 or 2

	var domNode = vNode.f
		? _VirtualDom_doc.createElementNS(vNode.f, vNode.c)
		: _VirtualDom_doc.createElement(vNode.c);

	if (_VirtualDom_divertHrefToApp && vNode.c == 'a')
	{
		domNode.addEventListener('click', _VirtualDom_divertHrefToApp(domNode));
	}

	_VirtualDom_applyFacts(domNode, eventNode, vNode.d);

	for (var kids = vNode.e, i = 0; i < kids.length; i++)
	{
		_VirtualDom_appendChild(domNode, _VirtualDom_render(tag === 1 ? kids[i] : kids[i].b, eventNode));
	}

	return domNode;
}



// APPLY FACTS


function _VirtualDom_applyFacts(domNode, eventNode, facts)
{
	for (var key in facts)
	{
		var value = facts[key];

		key === 'a1'
			? _VirtualDom_applyStyles(domNode, value)
			:
		key === 'a0'
			? _VirtualDom_applyEvents(domNode, eventNode, value)
			:
		key === 'a3'
			? _VirtualDom_applyAttrs(domNode, value)
			:
		key === 'a4'
			? _VirtualDom_applyAttrsNS(domNode, value)
			:
		((key !== 'value' && key !== 'checked') || domNode[key] !== value) && (domNode[key] = value);
	}
}



// APPLY STYLES


function _VirtualDom_applyStyles(domNode, styles)
{
	var domNodeStyle = domNode.style;

	for (var key in styles)
	{
		domNodeStyle[key] = styles[key];
	}
}



// APPLY ATTRS


function _VirtualDom_applyAttrs(domNode, attrs)
{
	for (var key in attrs)
	{
		var value = attrs[key];
		typeof value !== 'undefined'
			? domNode.setAttribute(key, value)
			: domNode.removeAttribute(key);
	}
}



// APPLY NAMESPACED ATTRS


function _VirtualDom_applyAttrsNS(domNode, nsAttrs)
{
	for (var key in nsAttrs)
	{
		var pair = nsAttrs[key];
		var namespace = pair.f;
		var value = pair.o;

		typeof value !== 'undefined'
			? domNode.setAttributeNS(namespace, key, value)
			: domNode.removeAttributeNS(namespace, key);
	}
}



// APPLY EVENTS


function _VirtualDom_applyEvents(domNode, eventNode, events)
{
	var allCallbacks = domNode.elmFs || (domNode.elmFs = {});

	for (var key in events)
	{
		var newHandler = events[key];
		var oldCallback = allCallbacks[key];

		if (!newHandler)
		{
			domNode.removeEventListener(key, oldCallback);
			allCallbacks[key] = undefined;
			continue;
		}

		if (oldCallback)
		{
			var oldHandler = oldCallback.q;
			if (oldHandler.$ === newHandler.$)
			{
				oldCallback.q = newHandler;
				continue;
			}
			domNode.removeEventListener(key, oldCallback);
		}

		oldCallback = _VirtualDom_makeCallback(eventNode, newHandler);
		domNode.addEventListener(key, oldCallback,
			_VirtualDom_passiveSupported
			&& { passive: $elm$virtual_dom$VirtualDom$toHandlerInt(newHandler) < 2 }
		);
		allCallbacks[key] = oldCallback;
	}
}



// PASSIVE EVENTS


var _VirtualDom_passiveSupported;

try
{
	window.addEventListener('t', null, Object.defineProperty({}, 'passive', {
		get: function() { _VirtualDom_passiveSupported = true; }
	}));
}
catch(e) {}



// EVENT HANDLERS


function _VirtualDom_makeCallback(eventNode, initialHandler)
{
	function callback(event)
	{
		var handler = callback.q;
		var result = _Json_runHelp(handler.a, event);

		if (!$elm$core$Result$isOk(result))
		{
			return;
		}

		var tag = $elm$virtual_dom$VirtualDom$toHandlerInt(handler);

		// 0 = Normal
		// 1 = MayStopPropagation
		// 2 = MayPreventDefault
		// 3 = Custom

		var value = result.a;
		var message = !tag ? value : tag < 3 ? value.a : value.c1;
		var stopPropagation = tag == 1 ? value.b : tag == 3 && value.dA;
		var currentEventNode = (
			stopPropagation && event.stopPropagation(),
			(tag == 2 ? value.b : tag == 3 && value.dr) && event.preventDefault(),
			eventNode
		);
		var tagger;
		var i;
		while (tagger = currentEventNode.j)
		{
			if (typeof tagger == 'function')
			{
				message = tagger(message);
			}
			else
			{
				for (var i = tagger.length; i--; )
				{
					message = tagger[i](message);
				}
			}
			currentEventNode = currentEventNode.p;
		}
		currentEventNode(message, stopPropagation); // stopPropagation implies isSync
	}

	callback.q = initialHandler;

	return callback;
}

function _VirtualDom_equalEvents(x, y)
{
	return x.$ == y.$ && _Json_equality(x.a, y.a);
}



// DIFF


// TODO: Should we do patches like in iOS?
//
// type Patch
//   = At Int Patch
//   | Batch (List Patch)
//   | Change ...
//
// How could it not be better?
//
function _VirtualDom_diff(x, y)
{
	var patches = [];
	_VirtualDom_diffHelp(x, y, patches, 0);
	return patches;
}


function _VirtualDom_pushPatch(patches, type, index, data)
{
	var patch = {
		$: type,
		r: index,
		s: data,
		t: undefined,
		u: undefined
	};
	patches.push(patch);
	return patch;
}


function _VirtualDom_diffHelp(x, y, patches, index)
{
	if (x === y)
	{
		return;
	}

	var xType = x.$;
	var yType = y.$;

	// Bail if you run into different types of nodes. Implies that the
	// structure has changed significantly and it's not worth a diff.
	if (xType !== yType)
	{
		if (xType === 1 && yType === 2)
		{
			y = _VirtualDom_dekey(y);
			yType = 1;
		}
		else
		{
			_VirtualDom_pushPatch(patches, 0, index, y);
			return;
		}
	}

	// Now we know that both nodes are the same $.
	switch (yType)
	{
		case 5:
			var xRefs = x.l;
			var yRefs = y.l;
			var i = xRefs.length;
			var same = i === yRefs.length;
			while (same && i--)
			{
				same = xRefs[i] === yRefs[i];
			}
			if (same)
			{
				y.k = x.k;
				return;
			}
			y.k = y.m();
			var subPatches = [];
			_VirtualDom_diffHelp(x.k, y.k, subPatches, 0);
			subPatches.length > 0 && _VirtualDom_pushPatch(patches, 1, index, subPatches);
			return;

		case 4:
			// gather nested taggers
			var xTaggers = x.j;
			var yTaggers = y.j;
			var nesting = false;

			var xSubNode = x.k;
			while (xSubNode.$ === 4)
			{
				nesting = true;

				typeof xTaggers !== 'object'
					? xTaggers = [xTaggers, xSubNode.j]
					: xTaggers.push(xSubNode.j);

				xSubNode = xSubNode.k;
			}

			var ySubNode = y.k;
			while (ySubNode.$ === 4)
			{
				nesting = true;

				typeof yTaggers !== 'object'
					? yTaggers = [yTaggers, ySubNode.j]
					: yTaggers.push(ySubNode.j);

				ySubNode = ySubNode.k;
			}

			// Just bail if different numbers of taggers. This implies the
			// structure of the virtual DOM has changed.
			if (nesting && xTaggers.length !== yTaggers.length)
			{
				_VirtualDom_pushPatch(patches, 0, index, y);
				return;
			}

			// check if taggers are "the same"
			if (nesting ? !_VirtualDom_pairwiseRefEqual(xTaggers, yTaggers) : xTaggers !== yTaggers)
			{
				_VirtualDom_pushPatch(patches, 2, index, yTaggers);
			}

			// diff everything below the taggers
			_VirtualDom_diffHelp(xSubNode, ySubNode, patches, index + 1);
			return;

		case 0:
			if (x.a !== y.a)
			{
				_VirtualDom_pushPatch(patches, 3, index, y.a);
			}
			return;

		case 1:
			_VirtualDom_diffNodes(x, y, patches, index, _VirtualDom_diffKids);
			return;

		case 2:
			_VirtualDom_diffNodes(x, y, patches, index, _VirtualDom_diffKeyedKids);
			return;

		case 3:
			if (x.h !== y.h)
			{
				_VirtualDom_pushPatch(patches, 0, index, y);
				return;
			}

			var factsDiff = _VirtualDom_diffFacts(x.d, y.d);
			factsDiff && _VirtualDom_pushPatch(patches, 4, index, factsDiff);

			var patch = y.i(x.g, y.g);
			patch && _VirtualDom_pushPatch(patches, 5, index, patch);

			return;
	}
}

// assumes the incoming arrays are the same length
function _VirtualDom_pairwiseRefEqual(as, bs)
{
	for (var i = 0; i < as.length; i++)
	{
		if (as[i] !== bs[i])
		{
			return false;
		}
	}

	return true;
}

function _VirtualDom_diffNodes(x, y, patches, index, diffKids)
{
	// Bail if obvious indicators have changed. Implies more serious
	// structural changes such that it's not worth it to diff.
	if (x.c !== y.c || x.f !== y.f)
	{
		_VirtualDom_pushPatch(patches, 0, index, y);
		return;
	}

	var factsDiff = _VirtualDom_diffFacts(x.d, y.d);
	factsDiff && _VirtualDom_pushPatch(patches, 4, index, factsDiff);

	diffKids(x, y, patches, index);
}



// DIFF FACTS


// TODO Instead of creating a new diff object, it's possible to just test if
// there *is* a diff. During the actual patch, do the diff again and make the
// modifications directly. This way, there's no new allocations. Worth it?
function _VirtualDom_diffFacts(x, y, category)
{
	var diff;

	// look for changes and removals
	for (var xKey in x)
	{
		if (xKey === 'a1' || xKey === 'a0' || xKey === 'a3' || xKey === 'a4')
		{
			var subDiff = _VirtualDom_diffFacts(x[xKey], y[xKey] || {}, xKey);
			if (subDiff)
			{
				diff = diff || {};
				diff[xKey] = subDiff;
			}
			continue;
		}

		// remove if not in the new facts
		if (!(xKey in y))
		{
			diff = diff || {};
			diff[xKey] =
				!category
					? (typeof x[xKey] === 'string' ? '' : null)
					:
				(category === 'a1')
					? ''
					:
				(category === 'a0' || category === 'a3')
					? undefined
					:
				{ f: x[xKey].f, o: undefined };

			continue;
		}

		var xValue = x[xKey];
		var yValue = y[xKey];

		// reference equal, so don't worry about it
		if (xValue === yValue && xKey !== 'value' && xKey !== 'checked'
			|| category === 'a0' && _VirtualDom_equalEvents(xValue, yValue))
		{
			continue;
		}

		diff = diff || {};
		diff[xKey] = yValue;
	}

	// add new stuff
	for (var yKey in y)
	{
		if (!(yKey in x))
		{
			diff = diff || {};
			diff[yKey] = y[yKey];
		}
	}

	return diff;
}



// DIFF KIDS


function _VirtualDom_diffKids(xParent, yParent, patches, index)
{
	var xKids = xParent.e;
	var yKids = yParent.e;

	var xLen = xKids.length;
	var yLen = yKids.length;

	// FIGURE OUT IF THERE ARE INSERTS OR REMOVALS

	if (xLen > yLen)
	{
		_VirtualDom_pushPatch(patches, 6, index, {
			v: yLen,
			i: xLen - yLen
		});
	}
	else if (xLen < yLen)
	{
		_VirtualDom_pushPatch(patches, 7, index, {
			v: xLen,
			e: yKids
		});
	}

	// PAIRWISE DIFF EVERYTHING ELSE

	for (var minLen = xLen < yLen ? xLen : yLen, i = 0; i < minLen; i++)
	{
		var xKid = xKids[i];
		_VirtualDom_diffHelp(xKid, yKids[i], patches, ++index);
		index += xKid.b || 0;
	}
}



// KEYED DIFF


function _VirtualDom_diffKeyedKids(xParent, yParent, patches, rootIndex)
{
	var localPatches = [];

	var changes = {}; // Dict String Entry
	var inserts = []; // Array { index : Int, entry : Entry }
	// type Entry = { tag : String, vnode : VNode, index : Int, data : _ }

	var xKids = xParent.e;
	var yKids = yParent.e;
	var xLen = xKids.length;
	var yLen = yKids.length;
	var xIndex = 0;
	var yIndex = 0;

	var index = rootIndex;

	while (xIndex < xLen && yIndex < yLen)
	{
		var x = xKids[xIndex];
		var y = yKids[yIndex];

		var xKey = x.a;
		var yKey = y.a;
		var xNode = x.b;
		var yNode = y.b;

		var newMatch = undefined;
		var oldMatch = undefined;

		// check if keys match

		if (xKey === yKey)
		{
			index++;
			_VirtualDom_diffHelp(xNode, yNode, localPatches, index);
			index += xNode.b || 0;

			xIndex++;
			yIndex++;
			continue;
		}

		// look ahead 1 to detect insertions and removals.

		var xNext = xKids[xIndex + 1];
		var yNext = yKids[yIndex + 1];

		if (xNext)
		{
			var xNextKey = xNext.a;
			var xNextNode = xNext.b;
			oldMatch = yKey === xNextKey;
		}

		if (yNext)
		{
			var yNextKey = yNext.a;
			var yNextNode = yNext.b;
			newMatch = xKey === yNextKey;
		}


		// swap x and y
		if (newMatch && oldMatch)
		{
			index++;
			_VirtualDom_diffHelp(xNode, yNextNode, localPatches, index);
			_VirtualDom_insertNode(changes, localPatches, xKey, yNode, yIndex, inserts);
			index += xNode.b || 0;

			index++;
			_VirtualDom_removeNode(changes, localPatches, xKey, xNextNode, index);
			index += xNextNode.b || 0;

			xIndex += 2;
			yIndex += 2;
			continue;
		}

		// insert y
		if (newMatch)
		{
			index++;
			_VirtualDom_insertNode(changes, localPatches, yKey, yNode, yIndex, inserts);
			_VirtualDom_diffHelp(xNode, yNextNode, localPatches, index);
			index += xNode.b || 0;

			xIndex += 1;
			yIndex += 2;
			continue;
		}

		// remove x
		if (oldMatch)
		{
			index++;
			_VirtualDom_removeNode(changes, localPatches, xKey, xNode, index);
			index += xNode.b || 0;

			index++;
			_VirtualDom_diffHelp(xNextNode, yNode, localPatches, index);
			index += xNextNode.b || 0;

			xIndex += 2;
			yIndex += 1;
			continue;
		}

		// remove x, insert y
		if (xNext && xNextKey === yNextKey)
		{
			index++;
			_VirtualDom_removeNode(changes, localPatches, xKey, xNode, index);
			_VirtualDom_insertNode(changes, localPatches, yKey, yNode, yIndex, inserts);
			index += xNode.b || 0;

			index++;
			_VirtualDom_diffHelp(xNextNode, yNextNode, localPatches, index);
			index += xNextNode.b || 0;

			xIndex += 2;
			yIndex += 2;
			continue;
		}

		break;
	}

	// eat up any remaining nodes with removeNode and insertNode

	while (xIndex < xLen)
	{
		index++;
		var x = xKids[xIndex];
		var xNode = x.b;
		_VirtualDom_removeNode(changes, localPatches, x.a, xNode, index);
		index += xNode.b || 0;
		xIndex++;
	}

	while (yIndex < yLen)
	{
		var endInserts = endInserts || [];
		var y = yKids[yIndex];
		_VirtualDom_insertNode(changes, localPatches, y.a, y.b, undefined, endInserts);
		yIndex++;
	}

	if (localPatches.length > 0 || inserts.length > 0 || endInserts)
	{
		_VirtualDom_pushPatch(patches, 8, rootIndex, {
			w: localPatches,
			x: inserts,
			y: endInserts
		});
	}
}



// CHANGES FROM KEYED DIFF


var _VirtualDom_POSTFIX = '_elmW6BL';


function _VirtualDom_insertNode(changes, localPatches, key, vnode, yIndex, inserts)
{
	var entry = changes[key];

	// never seen this key before
	if (!entry)
	{
		entry = {
			c: 0,
			z: vnode,
			r: yIndex,
			s: undefined
		};

		inserts.push({ r: yIndex, A: entry });
		changes[key] = entry;

		return;
	}

	// this key was removed earlier, a match!
	if (entry.c === 1)
	{
		inserts.push({ r: yIndex, A: entry });

		entry.c = 2;
		var subPatches = [];
		_VirtualDom_diffHelp(entry.z, vnode, subPatches, entry.r);
		entry.r = yIndex;
		entry.s.s = {
			w: subPatches,
			A: entry
		};

		return;
	}

	// this key has already been inserted or moved, a duplicate!
	_VirtualDom_insertNode(changes, localPatches, key + _VirtualDom_POSTFIX, vnode, yIndex, inserts);
}


function _VirtualDom_removeNode(changes, localPatches, key, vnode, index)
{
	var entry = changes[key];

	// never seen this key before
	if (!entry)
	{
		var patch = _VirtualDom_pushPatch(localPatches, 9, index, undefined);

		changes[key] = {
			c: 1,
			z: vnode,
			r: index,
			s: patch
		};

		return;
	}

	// this key was inserted earlier, a match!
	if (entry.c === 0)
	{
		entry.c = 2;
		var subPatches = [];
		_VirtualDom_diffHelp(vnode, entry.z, subPatches, index);

		_VirtualDom_pushPatch(localPatches, 9, index, {
			w: subPatches,
			A: entry
		});

		return;
	}

	// this key has already been removed or moved, a duplicate!
	_VirtualDom_removeNode(changes, localPatches, key + _VirtualDom_POSTFIX, vnode, index);
}



// ADD DOM NODES
//
// Each DOM node has an "index" assigned in order of traversal. It is important
// to minimize our crawl over the actual DOM, so these indexes (along with the
// descendantsCount of virtual nodes) let us skip touching entire subtrees of
// the DOM if we know there are no patches there.


function _VirtualDom_addDomNodes(domNode, vNode, patches, eventNode)
{
	_VirtualDom_addDomNodesHelp(domNode, vNode, patches, 0, 0, vNode.b, eventNode);
}


// assumes `patches` is non-empty and indexes increase monotonically.
function _VirtualDom_addDomNodesHelp(domNode, vNode, patches, i, low, high, eventNode)
{
	var patch = patches[i];
	var index = patch.r;

	while (index === low)
	{
		var patchType = patch.$;

		if (patchType === 1)
		{
			_VirtualDom_addDomNodes(domNode, vNode.k, patch.s, eventNode);
		}
		else if (patchType === 8)
		{
			patch.t = domNode;
			patch.u = eventNode;

			var subPatches = patch.s.w;
			if (subPatches.length > 0)
			{
				_VirtualDom_addDomNodesHelp(domNode, vNode, subPatches, 0, low, high, eventNode);
			}
		}
		else if (patchType === 9)
		{
			patch.t = domNode;
			patch.u = eventNode;

			var data = patch.s;
			if (data)
			{
				data.A.s = domNode;
				var subPatches = data.w;
				if (subPatches.length > 0)
				{
					_VirtualDom_addDomNodesHelp(domNode, vNode, subPatches, 0, low, high, eventNode);
				}
			}
		}
		else
		{
			patch.t = domNode;
			patch.u = eventNode;
		}

		i++;

		if (!(patch = patches[i]) || (index = patch.r) > high)
		{
			return i;
		}
	}

	var tag = vNode.$;

	if (tag === 4)
	{
		var subNode = vNode.k;

		while (subNode.$ === 4)
		{
			subNode = subNode.k;
		}

		return _VirtualDom_addDomNodesHelp(domNode, subNode, patches, i, low + 1, high, domNode.elm_event_node_ref);
	}

	// tag must be 1 or 2 at this point

	var vKids = vNode.e;
	var childNodes = domNode.childNodes;
	for (var j = 0; j < vKids.length; j++)
	{
		low++;
		var vKid = tag === 1 ? vKids[j] : vKids[j].b;
		var nextLow = low + (vKid.b || 0);
		if (low <= index && index <= nextLow)
		{
			i = _VirtualDom_addDomNodesHelp(childNodes[j], vKid, patches, i, low, nextLow, eventNode);
			if (!(patch = patches[i]) || (index = patch.r) > high)
			{
				return i;
			}
		}
		low = nextLow;
	}
	return i;
}



// APPLY PATCHES


function _VirtualDom_applyPatches(rootDomNode, oldVirtualNode, patches, eventNode)
{
	if (patches.length === 0)
	{
		return rootDomNode;
	}

	_VirtualDom_addDomNodes(rootDomNode, oldVirtualNode, patches, eventNode);
	return _VirtualDom_applyPatchesHelp(rootDomNode, patches);
}

function _VirtualDom_applyPatchesHelp(rootDomNode, patches)
{
	for (var i = 0; i < patches.length; i++)
	{
		var patch = patches[i];
		var localDomNode = patch.t
		var newNode = _VirtualDom_applyPatch(localDomNode, patch);
		if (localDomNode === rootDomNode)
		{
			rootDomNode = newNode;
		}
	}
	return rootDomNode;
}

function _VirtualDom_applyPatch(domNode, patch)
{
	switch (patch.$)
	{
		case 0:
			return _VirtualDom_applyPatchRedraw(domNode, patch.s, patch.u);

		case 4:
			_VirtualDom_applyFacts(domNode, patch.u, patch.s);
			return domNode;

		case 3:
			domNode.replaceData(0, domNode.length, patch.s);
			return domNode;

		case 1:
			return _VirtualDom_applyPatchesHelp(domNode, patch.s);

		case 2:
			if (domNode.elm_event_node_ref)
			{
				domNode.elm_event_node_ref.j = patch.s;
			}
			else
			{
				domNode.elm_event_node_ref = { j: patch.s, p: patch.u };
			}
			return domNode;

		case 6:
			var data = patch.s;
			for (var i = 0; i < data.i; i++)
			{
				domNode.removeChild(domNode.childNodes[data.v]);
			}
			return domNode;

		case 7:
			var data = patch.s;
			var kids = data.e;
			var i = data.v;
			var theEnd = domNode.childNodes[i];
			for (; i < kids.length; i++)
			{
				domNode.insertBefore(_VirtualDom_render(kids[i], patch.u), theEnd);
			}
			return domNode;

		case 9:
			var data = patch.s;
			if (!data)
			{
				domNode.parentNode.removeChild(domNode);
				return domNode;
			}
			var entry = data.A;
			if (typeof entry.r !== 'undefined')
			{
				domNode.parentNode.removeChild(domNode);
			}
			entry.s = _VirtualDom_applyPatchesHelp(domNode, data.w);
			return domNode;

		case 8:
			return _VirtualDom_applyPatchReorder(domNode, patch);

		case 5:
			return patch.s(domNode);

		default:
			_Debug_crash(10); // 'Ran into an unknown patch!'
	}
}


function _VirtualDom_applyPatchRedraw(domNode, vNode, eventNode)
{
	var parentNode = domNode.parentNode;
	var newNode = _VirtualDom_render(vNode, eventNode);

	if (!newNode.elm_event_node_ref)
	{
		newNode.elm_event_node_ref = domNode.elm_event_node_ref;
	}

	if (parentNode && newNode !== domNode)
	{
		parentNode.replaceChild(newNode, domNode);
	}
	return newNode;
}


function _VirtualDom_applyPatchReorder(domNode, patch)
{
	var data = patch.s;

	// remove end inserts
	var frag = _VirtualDom_applyPatchReorderEndInsertsHelp(data.y, patch);

	// removals
	domNode = _VirtualDom_applyPatchesHelp(domNode, data.w);

	// inserts
	var inserts = data.x;
	for (var i = 0; i < inserts.length; i++)
	{
		var insert = inserts[i];
		var entry = insert.A;
		var node = entry.c === 2
			? entry.s
			: _VirtualDom_render(entry.z, patch.u);
		domNode.insertBefore(node, domNode.childNodes[insert.r]);
	}

	// add end inserts
	if (frag)
	{
		_VirtualDom_appendChild(domNode, frag);
	}

	return domNode;
}


function _VirtualDom_applyPatchReorderEndInsertsHelp(endInserts, patch)
{
	if (!endInserts)
	{
		return;
	}

	var frag = _VirtualDom_doc.createDocumentFragment();
	for (var i = 0; i < endInserts.length; i++)
	{
		var insert = endInserts[i];
		var entry = insert.A;
		_VirtualDom_appendChild(frag, entry.c === 2
			? entry.s
			: _VirtualDom_render(entry.z, patch.u)
		);
	}
	return frag;
}


function _VirtualDom_virtualize(node)
{
	// TEXT NODES

	if (node.nodeType === 3)
	{
		return _VirtualDom_text(node.textContent);
	}


	// WEIRD NODES

	if (node.nodeType !== 1)
	{
		return _VirtualDom_text('');
	}


	// ELEMENT NODES

	var attrList = _List_Nil;
	var attrs = node.attributes;
	for (var i = attrs.length; i--; )
	{
		var attr = attrs[i];
		var name = attr.name;
		var value = attr.value;
		attrList = _List_Cons( A2(_VirtualDom_attribute, name, value), attrList );
	}

	var tag = node.tagName.toLowerCase();
	var kidList = _List_Nil;
	var kids = node.childNodes;

	for (var i = kids.length; i--; )
	{
		kidList = _List_Cons(_VirtualDom_virtualize(kids[i]), kidList);
	}
	return A3(_VirtualDom_node, tag, attrList, kidList);
}

function _VirtualDom_dekey(keyedNode)
{
	var keyedKids = keyedNode.e;
	var len = keyedKids.length;
	var kids = new Array(len);
	for (var i = 0; i < len; i++)
	{
		kids[i] = keyedKids[i].b;
	}

	return {
		$: 1,
		c: keyedNode.c,
		d: keyedNode.d,
		e: kids,
		f: keyedNode.f,
		b: keyedNode.b
	};
}




// ELEMENT


var _Debugger_element;

var _Browser_element = _Debugger_element || F4(function(impl, flagDecoder, debugMetadata, args)
{
	return _Platform_initialize(
		flagDecoder,
		args,
		impl.cS,
		impl.dN,
		impl.dB,
		function(sendToApp, initialModel) {
			var view = impl.dQ;
			/**/
			var domNode = args['node'];
			//*/
			/**_UNUSED/
			var domNode = args && args['node'] ? args['node'] : _Debug_crash(0);
			//*/
			var currNode = _VirtualDom_virtualize(domNode);

			return _Browser_makeAnimator(initialModel, function(model)
			{
				var nextNode = view(model);
				var patches = _VirtualDom_diff(currNode, nextNode);
				domNode = _VirtualDom_applyPatches(domNode, currNode, patches, sendToApp);
				currNode = nextNode;
			});
		}
	);
});



// DOCUMENT


var _Debugger_document;

var _Browser_document = _Debugger_document || F4(function(impl, flagDecoder, debugMetadata, args)
{
	return _Platform_initialize(
		flagDecoder,
		args,
		impl.cS,
		impl.dN,
		impl.dB,
		function(sendToApp, initialModel) {
			var divertHrefToApp = impl.aI && impl.aI(sendToApp)
			var view = impl.dQ;
			var title = _VirtualDom_doc.title;
			var bodyNode = _VirtualDom_doc.body;
			var currNode = _VirtualDom_virtualize(bodyNode);
			return _Browser_makeAnimator(initialModel, function(model)
			{
				_VirtualDom_divertHrefToApp = divertHrefToApp;
				var doc = view(model);
				var nextNode = _VirtualDom_node('body')(_List_Nil)(doc.cr);
				var patches = _VirtualDom_diff(currNode, nextNode);
				bodyNode = _VirtualDom_applyPatches(bodyNode, currNode, patches, sendToApp);
				currNode = nextNode;
				_VirtualDom_divertHrefToApp = 0;
				(title !== doc.dJ) && (_VirtualDom_doc.title = title = doc.dJ);
			});
		}
	);
});



// ANIMATION


var _Browser_cancelAnimationFrame =
	typeof cancelAnimationFrame !== 'undefined'
		? cancelAnimationFrame
		: function(id) { clearTimeout(id); };

var _Browser_requestAnimationFrame =
	typeof requestAnimationFrame !== 'undefined'
		? requestAnimationFrame
		: function(callback) { return setTimeout(callback, 1000 / 60); };


function _Browser_makeAnimator(model, draw)
{
	draw(model);

	var state = 0;

	function updateIfNeeded()
	{
		state = state === 1
			? 0
			: ( _Browser_requestAnimationFrame(updateIfNeeded), draw(model), 1 );
	}

	return function(nextModel, isSync)
	{
		model = nextModel;

		isSync
			? ( draw(model),
				state === 2 && (state = 1)
				)
			: ( state === 0 && _Browser_requestAnimationFrame(updateIfNeeded),
				state = 2
				);
	};
}



// APPLICATION


function _Browser_application(impl)
{
	var onUrlChange = impl.df;
	var onUrlRequest = impl.dg;
	var key = function() { key.a(onUrlChange(_Browser_getUrl())); };

	return _Browser_document({
		aI: function(sendToApp)
		{
			key.a = sendToApp;
			_Browser_window.addEventListener('popstate', key);
			_Browser_window.navigator.userAgent.indexOf('Trident') < 0 || _Browser_window.addEventListener('hashchange', key);

			return F2(function(domNode, event)
			{
				if (!event.ctrlKey && !event.metaKey && !event.shiftKey && event.button < 1 && !domNode.target && !domNode.hasAttribute('download'))
				{
					event.preventDefault();
					var href = domNode.href;
					var curr = _Browser_getUrl();
					var next = $elm$url$Url$fromString(href).a;
					sendToApp(onUrlRequest(
						(next
							&& curr.bH === next.bH
							&& curr.bd === next.bd
							&& curr.bE.a === next.bE.a
						)
							? $elm$browser$Browser$Internal(next)
							: $elm$browser$Browser$External(href)
					));
				}
			});
		},
		cS: function(flags)
		{
			return A3(impl.cS, flags, _Browser_getUrl(), key);
		},
		dQ: impl.dQ,
		dN: impl.dN,
		dB: impl.dB
	});
}

function _Browser_getUrl()
{
	return $elm$url$Url$fromString(_VirtualDom_doc.location.href).a || _Debug_crash(1);
}

var _Browser_go = F2(function(key, n)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function() {
		n && history.go(n);
		key();
	}));
});

var _Browser_pushUrl = F2(function(key, url)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function() {
		history.pushState({}, '', url);
		key();
	}));
});

var _Browser_replaceUrl = F2(function(key, url)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function() {
		history.replaceState({}, '', url);
		key();
	}));
});



// GLOBAL EVENTS


var _Browser_fakeNode = { addEventListener: function() {}, removeEventListener: function() {} };
var _Browser_doc = typeof document !== 'undefined' ? document : _Browser_fakeNode;
var _Browser_window = typeof window !== 'undefined' ? window : _Browser_fakeNode;

var _Browser_on = F3(function(node, eventName, sendToSelf)
{
	return _Scheduler_spawn(_Scheduler_binding(function(callback)
	{
		function handler(event)	{ _Scheduler_rawSpawn(sendToSelf(event)); }
		node.addEventListener(eventName, handler, _VirtualDom_passiveSupported && { passive: true });
		return function() { node.removeEventListener(eventName, handler); };
	}));
});

var _Browser_decodeEvent = F2(function(decoder, event)
{
	var result = _Json_runHelp(decoder, event);
	return $elm$core$Result$isOk(result) ? $elm$core$Maybe$Just(result.a) : $elm$core$Maybe$Nothing;
});



// PAGE VISIBILITY


function _Browser_visibilityInfo()
{
	return (typeof _VirtualDom_doc.hidden !== 'undefined')
		? { aA: 'hidden', cu: 'visibilitychange' }
		:
	(typeof _VirtualDom_doc.mozHidden !== 'undefined')
		? { aA: 'mozHidden', cu: 'mozvisibilitychange' }
		:
	(typeof _VirtualDom_doc.msHidden !== 'undefined')
		? { aA: 'msHidden', cu: 'msvisibilitychange' }
		:
	(typeof _VirtualDom_doc.webkitHidden !== 'undefined')
		? { aA: 'webkitHidden', cu: 'webkitvisibilitychange' }
		: { aA: 'hidden', cu: 'visibilitychange' };
}



// ANIMATION FRAMES


function _Browser_rAF()
{
	return _Scheduler_binding(function(callback)
	{
		var id = _Browser_requestAnimationFrame(function() {
			callback(_Scheduler_succeed(Date.now()));
		});

		return function() {
			_Browser_cancelAnimationFrame(id);
		};
	});
}


function _Browser_now()
{
	return _Scheduler_binding(function(callback)
	{
		callback(_Scheduler_succeed(Date.now()));
	});
}



// DOM STUFF


function _Browser_withNode(id, doStuff)
{
	return _Scheduler_binding(function(callback)
	{
		_Browser_requestAnimationFrame(function() {
			var node = document.getElementById(id);
			callback(node
				? _Scheduler_succeed(doStuff(node))
				: _Scheduler_fail($elm$browser$Browser$Dom$NotFound(id))
			);
		});
	});
}


function _Browser_withWindow(doStuff)
{
	return _Scheduler_binding(function(callback)
	{
		_Browser_requestAnimationFrame(function() {
			callback(_Scheduler_succeed(doStuff()));
		});
	});
}


// FOCUS and BLUR


var _Browser_call = F2(function(functionName, id)
{
	return _Browser_withNode(id, function(node) {
		node[functionName]();
		return _Utils_Tuple0;
	});
});



// WINDOW VIEWPORT


function _Browser_getViewport()
{
	return {
		b_: _Browser_getScene(),
		cf: {
			ci: _Browser_window.pageXOffset,
			cj: _Browser_window.pageYOffset,
			ch: _Browser_doc.documentElement.clientWidth,
			bc: _Browser_doc.documentElement.clientHeight
		}
	};
}

function _Browser_getScene()
{
	var body = _Browser_doc.body;
	var elem = _Browser_doc.documentElement;
	return {
		ch: Math.max(body.scrollWidth, body.offsetWidth, elem.scrollWidth, elem.offsetWidth, elem.clientWidth),
		bc: Math.max(body.scrollHeight, body.offsetHeight, elem.scrollHeight, elem.offsetHeight, elem.clientHeight)
	};
}

var _Browser_setViewport = F2(function(x, y)
{
	return _Browser_withWindow(function()
	{
		_Browser_window.scroll(x, y);
		return _Utils_Tuple0;
	});
});



// ELEMENT VIEWPORT


function _Browser_getViewportOf(id)
{
	return _Browser_withNode(id, function(node)
	{
		return {
			b_: {
				ch: node.scrollWidth,
				bc: node.scrollHeight
			},
			cf: {
				ci: node.scrollLeft,
				cj: node.scrollTop,
				ch: node.clientWidth,
				bc: node.clientHeight
			}
		};
	});
}


var _Browser_setViewportOf = F3(function(id, x, y)
{
	return _Browser_withNode(id, function(node)
	{
		node.scrollLeft = x;
		node.scrollTop = y;
		return _Utils_Tuple0;
	});
});



// ELEMENT


function _Browser_getElement(id)
{
	return _Browser_withNode(id, function(node)
	{
		var rect = node.getBoundingClientRect();
		var x = _Browser_window.pageXOffset;
		var y = _Browser_window.pageYOffset;
		return {
			b_: _Browser_getScene(),
			cf: {
				ci: x,
				cj: y,
				ch: _Browser_doc.documentElement.clientWidth,
				bc: _Browser_doc.documentElement.clientHeight
			},
			cH: {
				ci: x + rect.left,
				cj: y + rect.top,
				ch: rect.width,
				bc: rect.height
			}
		};
	});
}



// LOAD and RELOAD


function _Browser_reload(skipCache)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function(callback)
	{
		_VirtualDom_doc.location.reload(skipCache);
	}));
}

function _Browser_load(url)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function(callback)
	{
		try
		{
			_Browser_window.location = url;
		}
		catch(err)
		{
			// Only Firefox can throw a NS_ERROR_MALFORMED_URI exception here.
			// Other browsers reload the page, so let's be consistent about that.
			_VirtualDom_doc.location.reload(false);
		}
	}));
}



var _Bitwise_and = F2(function(a, b)
{
	return a & b;
});

var _Bitwise_or = F2(function(a, b)
{
	return a | b;
});

var _Bitwise_xor = F2(function(a, b)
{
	return a ^ b;
});

function _Bitwise_complement(a)
{
	return ~a;
};

var _Bitwise_shiftLeftBy = F2(function(offset, a)
{
	return a << offset;
});

var _Bitwise_shiftRightBy = F2(function(offset, a)
{
	return a >> offset;
});

var _Bitwise_shiftRightZfBy = F2(function(offset, a)
{
	return a >>> offset;
});



// DECODER

var _File_decoder = _Json_decodePrim(function(value) {
	// NOTE: checks if `File` exists in case this is run on node
	return (typeof File !== 'undefined' && value instanceof File)
		? $elm$core$Result$Ok(value)
		: _Json_expecting('a FILE', value);
});


// METADATA

function _File_name(file) { return file.name; }
function _File_mime(file) { return file.type; }
function _File_size(file) { return file.size; }

function _File_lastModified(file)
{
	return $elm$time$Time$millisToPosix(file.lastModified);
}


// DOWNLOAD

var _File_downloadNode;

function _File_getDownloadNode()
{
	return _File_downloadNode || (_File_downloadNode = document.createElement('a'));
}

var _File_download = F3(function(name, mime, content)
{
	return _Scheduler_binding(function(callback)
	{
		var blob = new Blob([content], {type: mime});

		// for IE10+
		if (navigator.msSaveOrOpenBlob)
		{
			navigator.msSaveOrOpenBlob(blob, name);
			return;
		}

		// for HTML5
		var node = _File_getDownloadNode();
		var objectUrl = URL.createObjectURL(blob);
		node.href = objectUrl;
		node.download = name;
		_File_click(node);
		URL.revokeObjectURL(objectUrl);
	});
});

function _File_downloadUrl(href)
{
	return _Scheduler_binding(function(callback)
	{
		var node = _File_getDownloadNode();
		node.href = href;
		node.download = '';
		node.origin === location.origin || (node.target = '_blank');
		_File_click(node);
	});
}


// IE COMPATIBILITY

function _File_makeBytesSafeForInternetExplorer(bytes)
{
	// only needed by IE10 and IE11 to fix https://github.com/elm/file/issues/10
	// all other browsers can just run `new Blob([bytes])` directly with no problem
	//
	return new Uint8Array(bytes.buffer, bytes.byteOffset, bytes.byteLength);
}

function _File_click(node)
{
	// only needed by IE10 and IE11 to fix https://github.com/elm/file/issues/11
	// all other browsers have MouseEvent and do not need this conditional stuff
	//
	if (typeof MouseEvent === 'function')
	{
		node.dispatchEvent(new MouseEvent('click'));
	}
	else
	{
		var event = document.createEvent('MouseEvents');
		event.initMouseEvent('click', true, true, window, 0, 0, 0, 0, 0, false, false, false, false, 0, null);
		document.body.appendChild(node);
		node.dispatchEvent(event);
		document.body.removeChild(node);
	}
}


// UPLOAD

var _File_node;

function _File_uploadOne(mimes)
{
	return _Scheduler_binding(function(callback)
	{
		_File_node = document.createElement('input');
		_File_node.type = 'file';
		_File_node.accept = A2($elm$core$String$join, ',', mimes);
		_File_node.addEventListener('change', function(event)
		{
			callback(_Scheduler_succeed(event.target.files[0]));
		});
		_File_click(_File_node);
	});
}

function _File_uploadOneOrMore(mimes)
{
	return _Scheduler_binding(function(callback)
	{
		_File_node = document.createElement('input');
		_File_node.type = 'file';
		_File_node.multiple = true;
		_File_node.accept = A2($elm$core$String$join, ',', mimes);
		_File_node.addEventListener('change', function(event)
		{
			var elmFiles = _List_fromArray(event.target.files);
			callback(_Scheduler_succeed(_Utils_Tuple2(elmFiles.a, elmFiles.b)));
		});
		_File_click(_File_node);
	});
}


// CONTENT

function _File_toString(blob)
{
	return _Scheduler_binding(function(callback)
	{
		var reader = new FileReader();
		reader.addEventListener('loadend', function() {
			callback(_Scheduler_succeed(reader.result));
		});
		reader.readAsText(blob);
		return function() { reader.abort(); };
	});
}

function _File_toBytes(blob)
{
	return _Scheduler_binding(function(callback)
	{
		var reader = new FileReader();
		reader.addEventListener('loadend', function() {
			callback(_Scheduler_succeed(new DataView(reader.result)));
		});
		reader.readAsArrayBuffer(blob);
		return function() { reader.abort(); };
	});
}

function _File_toUrl(blob)
{
	return _Scheduler_binding(function(callback)
	{
		var reader = new FileReader();
		reader.addEventListener('loadend', function() {
			callback(_Scheduler_succeed(reader.result));
		});
		reader.readAsDataURL(blob);
		return function() { reader.abort(); };
	});
}

var $elm$core$Maybe$Just = function (a) {
	return {$: 0, a: a};
};
var $elm$core$Maybe$Nothing = {$: 1};
var $elm$core$Basics$EQ = 1;
var $elm$core$Basics$GT = 2;
var $elm$core$Basics$LT = 0;
var $elm$core$List$cons = _List_cons;
var $elm$core$Dict$foldr = F3(
	function (func, acc, t) {
		foldr:
		while (true) {
			if (t.$ === -2) {
				return acc;
			} else {
				var key = t.b;
				var value = t.c;
				var left = t.d;
				var right = t.e;
				var $temp$func = func,
					$temp$acc = A3(
					func,
					key,
					value,
					A3($elm$core$Dict$foldr, func, acc, right)),
					$temp$t = left;
				func = $temp$func;
				acc = $temp$acc;
				t = $temp$t;
				continue foldr;
			}
		}
	});
var $elm$core$Dict$toList = function (dict) {
	return A3(
		$elm$core$Dict$foldr,
		F3(
			function (key, value, list) {
				return A2(
					$elm$core$List$cons,
					_Utils_Tuple2(key, value),
					list);
			}),
		_List_Nil,
		dict);
};
var $elm$core$Dict$keys = function (dict) {
	return A3(
		$elm$core$Dict$foldr,
		F3(
			function (key, value, keyList) {
				return A2($elm$core$List$cons, key, keyList);
			}),
		_List_Nil,
		dict);
};
var $elm$core$Set$toList = function (_v0) {
	var dict = _v0;
	return $elm$core$Dict$keys(dict);
};
var $elm$core$Elm$JsArray$foldr = _JsArray_foldr;
var $elm$core$Array$foldr = F3(
	function (func, baseCase, _v0) {
		var tree = _v0.c;
		var tail = _v0.d;
		var helper = F2(
			function (node, acc) {
				if (!node.$) {
					var subTree = node.a;
					return A3($elm$core$Elm$JsArray$foldr, helper, acc, subTree);
				} else {
					var values = node.a;
					return A3($elm$core$Elm$JsArray$foldr, func, acc, values);
				}
			});
		return A3(
			$elm$core$Elm$JsArray$foldr,
			helper,
			A3($elm$core$Elm$JsArray$foldr, func, baseCase, tail),
			tree);
	});
var $elm$core$Array$toList = function (array) {
	return A3($elm$core$Array$foldr, $elm$core$List$cons, _List_Nil, array);
};
var $elm$core$Result$Err = function (a) {
	return {$: 1, a: a};
};
var $elm$json$Json$Decode$Failure = F2(
	function (a, b) {
		return {$: 3, a: a, b: b};
	});
var $elm$json$Json$Decode$Field = F2(
	function (a, b) {
		return {$: 0, a: a, b: b};
	});
var $elm$json$Json$Decode$Index = F2(
	function (a, b) {
		return {$: 1, a: a, b: b};
	});
var $elm$core$Result$Ok = function (a) {
	return {$: 0, a: a};
};
var $elm$json$Json$Decode$OneOf = function (a) {
	return {$: 2, a: a};
};
var $elm$core$Basics$False = 1;
var $elm$core$Basics$add = _Basics_add;
var $elm$core$String$all = _String_all;
var $elm$core$Basics$and = _Basics_and;
var $elm$core$Basics$append = _Utils_append;
var $elm$json$Json$Encode$encode = _Json_encode;
var $elm$core$String$fromInt = _String_fromNumber;
var $elm$core$String$join = F2(
	function (sep, chunks) {
		return A2(
			_String_join,
			sep,
			_List_toArray(chunks));
	});
var $elm$core$String$split = F2(
	function (sep, string) {
		return _List_fromArray(
			A2(_String_split, sep, string));
	});
var $elm$json$Json$Decode$indent = function (str) {
	return A2(
		$elm$core$String$join,
		'\n    ',
		A2($elm$core$String$split, '\n', str));
};
var $elm$core$List$foldl = F3(
	function (func, acc, list) {
		foldl:
		while (true) {
			if (!list.b) {
				return acc;
			} else {
				var x = list.a;
				var xs = list.b;
				var $temp$func = func,
					$temp$acc = A2(func, x, acc),
					$temp$list = xs;
				func = $temp$func;
				acc = $temp$acc;
				list = $temp$list;
				continue foldl;
			}
		}
	});
var $elm$core$List$length = function (xs) {
	return A3(
		$elm$core$List$foldl,
		F2(
			function (_v0, i) {
				return i + 1;
			}),
		0,
		xs);
};
var $elm$core$List$map2 = _List_map2;
var $elm$core$Basics$le = _Utils_le;
var $elm$core$Basics$sub = _Basics_sub;
var $elm$core$List$rangeHelp = F3(
	function (lo, hi, list) {
		rangeHelp:
		while (true) {
			if (_Utils_cmp(lo, hi) < 1) {
				var $temp$lo = lo,
					$temp$hi = hi - 1,
					$temp$list = A2($elm$core$List$cons, hi, list);
				lo = $temp$lo;
				hi = $temp$hi;
				list = $temp$list;
				continue rangeHelp;
			} else {
				return list;
			}
		}
	});
var $elm$core$List$range = F2(
	function (lo, hi) {
		return A3($elm$core$List$rangeHelp, lo, hi, _List_Nil);
	});
var $elm$core$List$indexedMap = F2(
	function (f, xs) {
		return A3(
			$elm$core$List$map2,
			f,
			A2(
				$elm$core$List$range,
				0,
				$elm$core$List$length(xs) - 1),
			xs);
	});
var $elm$core$Char$toCode = _Char_toCode;
var $elm$core$Char$isLower = function (_char) {
	var code = $elm$core$Char$toCode(_char);
	return (97 <= code) && (code <= 122);
};
var $elm$core$Char$isUpper = function (_char) {
	var code = $elm$core$Char$toCode(_char);
	return (code <= 90) && (65 <= code);
};
var $elm$core$Basics$or = _Basics_or;
var $elm$core$Char$isAlpha = function (_char) {
	return $elm$core$Char$isLower(_char) || $elm$core$Char$isUpper(_char);
};
var $elm$core$Char$isDigit = function (_char) {
	var code = $elm$core$Char$toCode(_char);
	return (code <= 57) && (48 <= code);
};
var $elm$core$Char$isAlphaNum = function (_char) {
	return $elm$core$Char$isLower(_char) || ($elm$core$Char$isUpper(_char) || $elm$core$Char$isDigit(_char));
};
var $elm$core$List$reverse = function (list) {
	return A3($elm$core$List$foldl, $elm$core$List$cons, _List_Nil, list);
};
var $elm$core$String$uncons = _String_uncons;
var $elm$json$Json$Decode$errorOneOf = F2(
	function (i, error) {
		return '\n\n(' + ($elm$core$String$fromInt(i + 1) + (') ' + $elm$json$Json$Decode$indent(
			$elm$json$Json$Decode$errorToString(error))));
	});
var $elm$json$Json$Decode$errorToString = function (error) {
	return A2($elm$json$Json$Decode$errorToStringHelp, error, _List_Nil);
};
var $elm$json$Json$Decode$errorToStringHelp = F2(
	function (error, context) {
		errorToStringHelp:
		while (true) {
			switch (error.$) {
				case 0:
					var f = error.a;
					var err = error.b;
					var isSimple = function () {
						var _v1 = $elm$core$String$uncons(f);
						if (_v1.$ === 1) {
							return false;
						} else {
							var _v2 = _v1.a;
							var _char = _v2.a;
							var rest = _v2.b;
							return $elm$core$Char$isAlpha(_char) && A2($elm$core$String$all, $elm$core$Char$isAlphaNum, rest);
						}
					}();
					var fieldName = isSimple ? ('.' + f) : ('[\'' + (f + '\']'));
					var $temp$error = err,
						$temp$context = A2($elm$core$List$cons, fieldName, context);
					error = $temp$error;
					context = $temp$context;
					continue errorToStringHelp;
				case 1:
					var i = error.a;
					var err = error.b;
					var indexName = '[' + ($elm$core$String$fromInt(i) + ']');
					var $temp$error = err,
						$temp$context = A2($elm$core$List$cons, indexName, context);
					error = $temp$error;
					context = $temp$context;
					continue errorToStringHelp;
				case 2:
					var errors = error.a;
					if (!errors.b) {
						return 'Ran into a Json.Decode.oneOf with no possibilities' + function () {
							if (!context.b) {
								return '!';
							} else {
								return ' at json' + A2(
									$elm$core$String$join,
									'',
									$elm$core$List$reverse(context));
							}
						}();
					} else {
						if (!errors.b.b) {
							var err = errors.a;
							var $temp$error = err,
								$temp$context = context;
							error = $temp$error;
							context = $temp$context;
							continue errorToStringHelp;
						} else {
							var starter = function () {
								if (!context.b) {
									return 'Json.Decode.oneOf';
								} else {
									return 'The Json.Decode.oneOf at json' + A2(
										$elm$core$String$join,
										'',
										$elm$core$List$reverse(context));
								}
							}();
							var introduction = starter + (' failed in the following ' + ($elm$core$String$fromInt(
								$elm$core$List$length(errors)) + ' ways:'));
							return A2(
								$elm$core$String$join,
								'\n\n',
								A2(
									$elm$core$List$cons,
									introduction,
									A2($elm$core$List$indexedMap, $elm$json$Json$Decode$errorOneOf, errors)));
						}
					}
				default:
					var msg = error.a;
					var json = error.b;
					var introduction = function () {
						if (!context.b) {
							return 'Problem with the given value:\n\n';
						} else {
							return 'Problem with the value at json' + (A2(
								$elm$core$String$join,
								'',
								$elm$core$List$reverse(context)) + ':\n\n    ');
						}
					}();
					return introduction + ($elm$json$Json$Decode$indent(
						A2($elm$json$Json$Encode$encode, 4, json)) + ('\n\n' + msg));
			}
		}
	});
var $elm$core$Array$branchFactor = 32;
var $elm$core$Array$Array_elm_builtin = F4(
	function (a, b, c, d) {
		return {$: 0, a: a, b: b, c: c, d: d};
	});
var $elm$core$Elm$JsArray$empty = _JsArray_empty;
var $elm$core$Basics$ceiling = _Basics_ceiling;
var $elm$core$Basics$fdiv = _Basics_fdiv;
var $elm$core$Basics$logBase = F2(
	function (base, number) {
		return _Basics_log(number) / _Basics_log(base);
	});
var $elm$core$Basics$toFloat = _Basics_toFloat;
var $elm$core$Array$shiftStep = $elm$core$Basics$ceiling(
	A2($elm$core$Basics$logBase, 2, $elm$core$Array$branchFactor));
var $elm$core$Array$empty = A4($elm$core$Array$Array_elm_builtin, 0, $elm$core$Array$shiftStep, $elm$core$Elm$JsArray$empty, $elm$core$Elm$JsArray$empty);
var $elm$core$Elm$JsArray$initialize = _JsArray_initialize;
var $elm$core$Array$Leaf = function (a) {
	return {$: 1, a: a};
};
var $elm$core$Basics$apL = F2(
	function (f, x) {
		return f(x);
	});
var $elm$core$Basics$apR = F2(
	function (x, f) {
		return f(x);
	});
var $elm$core$Basics$eq = _Utils_equal;
var $elm$core$Basics$floor = _Basics_floor;
var $elm$core$Elm$JsArray$length = _JsArray_length;
var $elm$core$Basics$gt = _Utils_gt;
var $elm$core$Basics$max = F2(
	function (x, y) {
		return (_Utils_cmp(x, y) > 0) ? x : y;
	});
var $elm$core$Basics$mul = _Basics_mul;
var $elm$core$Array$SubTree = function (a) {
	return {$: 0, a: a};
};
var $elm$core$Elm$JsArray$initializeFromList = _JsArray_initializeFromList;
var $elm$core$Array$compressNodes = F2(
	function (nodes, acc) {
		compressNodes:
		while (true) {
			var _v0 = A2($elm$core$Elm$JsArray$initializeFromList, $elm$core$Array$branchFactor, nodes);
			var node = _v0.a;
			var remainingNodes = _v0.b;
			var newAcc = A2(
				$elm$core$List$cons,
				$elm$core$Array$SubTree(node),
				acc);
			if (!remainingNodes.b) {
				return $elm$core$List$reverse(newAcc);
			} else {
				var $temp$nodes = remainingNodes,
					$temp$acc = newAcc;
				nodes = $temp$nodes;
				acc = $temp$acc;
				continue compressNodes;
			}
		}
	});
var $elm$core$Tuple$first = function (_v0) {
	var x = _v0.a;
	return x;
};
var $elm$core$Array$treeFromBuilder = F2(
	function (nodeList, nodeListSize) {
		treeFromBuilder:
		while (true) {
			var newNodeSize = $elm$core$Basics$ceiling(nodeListSize / $elm$core$Array$branchFactor);
			if (newNodeSize === 1) {
				return A2($elm$core$Elm$JsArray$initializeFromList, $elm$core$Array$branchFactor, nodeList).a;
			} else {
				var $temp$nodeList = A2($elm$core$Array$compressNodes, nodeList, _List_Nil),
					$temp$nodeListSize = newNodeSize;
				nodeList = $temp$nodeList;
				nodeListSize = $temp$nodeListSize;
				continue treeFromBuilder;
			}
		}
	});
var $elm$core$Array$builderToArray = F2(
	function (reverseNodeList, builder) {
		if (!builder.e) {
			return A4(
				$elm$core$Array$Array_elm_builtin,
				$elm$core$Elm$JsArray$length(builder.g),
				$elm$core$Array$shiftStep,
				$elm$core$Elm$JsArray$empty,
				builder.g);
		} else {
			var treeLen = builder.e * $elm$core$Array$branchFactor;
			var depth = $elm$core$Basics$floor(
				A2($elm$core$Basics$logBase, $elm$core$Array$branchFactor, treeLen - 1));
			var correctNodeList = reverseNodeList ? $elm$core$List$reverse(builder.h) : builder.h;
			var tree = A2($elm$core$Array$treeFromBuilder, correctNodeList, builder.e);
			return A4(
				$elm$core$Array$Array_elm_builtin,
				$elm$core$Elm$JsArray$length(builder.g) + treeLen,
				A2($elm$core$Basics$max, 5, depth * $elm$core$Array$shiftStep),
				tree,
				builder.g);
		}
	});
var $elm$core$Basics$idiv = _Basics_idiv;
var $elm$core$Basics$lt = _Utils_lt;
var $elm$core$Array$initializeHelp = F5(
	function (fn, fromIndex, len, nodeList, tail) {
		initializeHelp:
		while (true) {
			if (fromIndex < 0) {
				return A2(
					$elm$core$Array$builderToArray,
					false,
					{h: nodeList, e: (len / $elm$core$Array$branchFactor) | 0, g: tail});
			} else {
				var leaf = $elm$core$Array$Leaf(
					A3($elm$core$Elm$JsArray$initialize, $elm$core$Array$branchFactor, fromIndex, fn));
				var $temp$fn = fn,
					$temp$fromIndex = fromIndex - $elm$core$Array$branchFactor,
					$temp$len = len,
					$temp$nodeList = A2($elm$core$List$cons, leaf, nodeList),
					$temp$tail = tail;
				fn = $temp$fn;
				fromIndex = $temp$fromIndex;
				len = $temp$len;
				nodeList = $temp$nodeList;
				tail = $temp$tail;
				continue initializeHelp;
			}
		}
	});
var $elm$core$Basics$remainderBy = _Basics_remainderBy;
var $elm$core$Array$initialize = F2(
	function (len, fn) {
		if (len <= 0) {
			return $elm$core$Array$empty;
		} else {
			var tailLen = len % $elm$core$Array$branchFactor;
			var tail = A3($elm$core$Elm$JsArray$initialize, tailLen, len - tailLen, fn);
			var initialFromIndex = (len - tailLen) - $elm$core$Array$branchFactor;
			return A5($elm$core$Array$initializeHelp, fn, initialFromIndex, len, _List_Nil, tail);
		}
	});
var $elm$core$Basics$True = 0;
var $elm$core$Result$isOk = function (result) {
	if (!result.$) {
		return true;
	} else {
		return false;
	}
};
var $elm$json$Json$Decode$map = _Json_map1;
var $elm$json$Json$Decode$map2 = _Json_map2;
var $elm$json$Json$Decode$succeed = _Json_succeed;
var $elm$virtual_dom$VirtualDom$toHandlerInt = function (handler) {
	switch (handler.$) {
		case 0:
			return 0;
		case 1:
			return 1;
		case 2:
			return 2;
		default:
			return 3;
	}
};
var $elm$browser$Browser$External = function (a) {
	return {$: 1, a: a};
};
var $elm$browser$Browser$Internal = function (a) {
	return {$: 0, a: a};
};
var $elm$core$Basics$identity = function (x) {
	return x;
};
var $elm$browser$Browser$Dom$NotFound = $elm$core$Basics$identity;
var $elm$url$Url$Http = 0;
var $elm$url$Url$Https = 1;
var $elm$url$Url$Url = F6(
	function (protocol, host, port_, path, query, fragment) {
		return {a7: fragment, bd: host, bB: path, bE: port_, bH: protocol, bI: query};
	});
var $elm$core$String$contains = _String_contains;
var $elm$core$String$length = _String_length;
var $elm$core$String$slice = _String_slice;
var $elm$core$String$dropLeft = F2(
	function (n, string) {
		return (n < 1) ? string : A3(
			$elm$core$String$slice,
			n,
			$elm$core$String$length(string),
			string);
	});
var $elm$core$String$indexes = _String_indexes;
var $elm$core$String$isEmpty = function (string) {
	return string === '';
};
var $elm$core$String$left = F2(
	function (n, string) {
		return (n < 1) ? '' : A3($elm$core$String$slice, 0, n, string);
	});
var $elm$core$String$toInt = _String_toInt;
var $elm$url$Url$chompBeforePath = F5(
	function (protocol, path, params, frag, str) {
		if ($elm$core$String$isEmpty(str) || A2($elm$core$String$contains, '@', str)) {
			return $elm$core$Maybe$Nothing;
		} else {
			var _v0 = A2($elm$core$String$indexes, ':', str);
			if (!_v0.b) {
				return $elm$core$Maybe$Just(
					A6($elm$url$Url$Url, protocol, str, $elm$core$Maybe$Nothing, path, params, frag));
			} else {
				if (!_v0.b.b) {
					var i = _v0.a;
					var _v1 = $elm$core$String$toInt(
						A2($elm$core$String$dropLeft, i + 1, str));
					if (_v1.$ === 1) {
						return $elm$core$Maybe$Nothing;
					} else {
						var port_ = _v1;
						return $elm$core$Maybe$Just(
							A6(
								$elm$url$Url$Url,
								protocol,
								A2($elm$core$String$left, i, str),
								port_,
								path,
								params,
								frag));
					}
				} else {
					return $elm$core$Maybe$Nothing;
				}
			}
		}
	});
var $elm$url$Url$chompBeforeQuery = F4(
	function (protocol, params, frag, str) {
		if ($elm$core$String$isEmpty(str)) {
			return $elm$core$Maybe$Nothing;
		} else {
			var _v0 = A2($elm$core$String$indexes, '/', str);
			if (!_v0.b) {
				return A5($elm$url$Url$chompBeforePath, protocol, '/', params, frag, str);
			} else {
				var i = _v0.a;
				return A5(
					$elm$url$Url$chompBeforePath,
					protocol,
					A2($elm$core$String$dropLeft, i, str),
					params,
					frag,
					A2($elm$core$String$left, i, str));
			}
		}
	});
var $elm$url$Url$chompBeforeFragment = F3(
	function (protocol, frag, str) {
		if ($elm$core$String$isEmpty(str)) {
			return $elm$core$Maybe$Nothing;
		} else {
			var _v0 = A2($elm$core$String$indexes, '?', str);
			if (!_v0.b) {
				return A4($elm$url$Url$chompBeforeQuery, protocol, $elm$core$Maybe$Nothing, frag, str);
			} else {
				var i = _v0.a;
				return A4(
					$elm$url$Url$chompBeforeQuery,
					protocol,
					$elm$core$Maybe$Just(
						A2($elm$core$String$dropLeft, i + 1, str)),
					frag,
					A2($elm$core$String$left, i, str));
			}
		}
	});
var $elm$url$Url$chompAfterProtocol = F2(
	function (protocol, str) {
		if ($elm$core$String$isEmpty(str)) {
			return $elm$core$Maybe$Nothing;
		} else {
			var _v0 = A2($elm$core$String$indexes, '#', str);
			if (!_v0.b) {
				return A3($elm$url$Url$chompBeforeFragment, protocol, $elm$core$Maybe$Nothing, str);
			} else {
				var i = _v0.a;
				return A3(
					$elm$url$Url$chompBeforeFragment,
					protocol,
					$elm$core$Maybe$Just(
						A2($elm$core$String$dropLeft, i + 1, str)),
					A2($elm$core$String$left, i, str));
			}
		}
	});
var $elm$core$String$startsWith = _String_startsWith;
var $elm$url$Url$fromString = function (str) {
	return A2($elm$core$String$startsWith, 'http://', str) ? A2(
		$elm$url$Url$chompAfterProtocol,
		0,
		A2($elm$core$String$dropLeft, 7, str)) : (A2($elm$core$String$startsWith, 'https://', str) ? A2(
		$elm$url$Url$chompAfterProtocol,
		1,
		A2($elm$core$String$dropLeft, 8, str)) : $elm$core$Maybe$Nothing);
};
var $elm$core$Basics$never = function (_v0) {
	never:
	while (true) {
		var nvr = _v0;
		var $temp$_v0 = nvr;
		_v0 = $temp$_v0;
		continue never;
	}
};
var $elm$core$Task$Perform = $elm$core$Basics$identity;
var $elm$core$Task$succeed = _Scheduler_succeed;
var $elm$core$Task$init = $elm$core$Task$succeed(0);
var $elm$core$List$foldrHelper = F4(
	function (fn, acc, ctr, ls) {
		if (!ls.b) {
			return acc;
		} else {
			var a = ls.a;
			var r1 = ls.b;
			if (!r1.b) {
				return A2(fn, a, acc);
			} else {
				var b = r1.a;
				var r2 = r1.b;
				if (!r2.b) {
					return A2(
						fn,
						a,
						A2(fn, b, acc));
				} else {
					var c = r2.a;
					var r3 = r2.b;
					if (!r3.b) {
						return A2(
							fn,
							a,
							A2(
								fn,
								b,
								A2(fn, c, acc)));
					} else {
						var d = r3.a;
						var r4 = r3.b;
						var res = (ctr > 500) ? A3(
							$elm$core$List$foldl,
							fn,
							acc,
							$elm$core$List$reverse(r4)) : A4($elm$core$List$foldrHelper, fn, acc, ctr + 1, r4);
						return A2(
							fn,
							a,
							A2(
								fn,
								b,
								A2(
									fn,
									c,
									A2(fn, d, res))));
					}
				}
			}
		}
	});
var $elm$core$List$foldr = F3(
	function (fn, acc, ls) {
		return A4($elm$core$List$foldrHelper, fn, acc, 0, ls);
	});
var $elm$core$List$map = F2(
	function (f, xs) {
		return A3(
			$elm$core$List$foldr,
			F2(
				function (x, acc) {
					return A2(
						$elm$core$List$cons,
						f(x),
						acc);
				}),
			_List_Nil,
			xs);
	});
var $elm$core$Task$andThen = _Scheduler_andThen;
var $elm$core$Task$map = F2(
	function (func, taskA) {
		return A2(
			$elm$core$Task$andThen,
			function (a) {
				return $elm$core$Task$succeed(
					func(a));
			},
			taskA);
	});
var $elm$core$Task$map2 = F3(
	function (func, taskA, taskB) {
		return A2(
			$elm$core$Task$andThen,
			function (a) {
				return A2(
					$elm$core$Task$andThen,
					function (b) {
						return $elm$core$Task$succeed(
							A2(func, a, b));
					},
					taskB);
			},
			taskA);
	});
var $elm$core$Task$sequence = function (tasks) {
	return A3(
		$elm$core$List$foldr,
		$elm$core$Task$map2($elm$core$List$cons),
		$elm$core$Task$succeed(_List_Nil),
		tasks);
};
var $elm$core$Platform$sendToApp = _Platform_sendToApp;
var $elm$core$Task$spawnCmd = F2(
	function (router, _v0) {
		var task = _v0;
		return _Scheduler_spawn(
			A2(
				$elm$core$Task$andThen,
				$elm$core$Platform$sendToApp(router),
				task));
	});
var $elm$core$Task$onEffects = F3(
	function (router, commands, state) {
		return A2(
			$elm$core$Task$map,
			function (_v0) {
				return 0;
			},
			$elm$core$Task$sequence(
				A2(
					$elm$core$List$map,
					$elm$core$Task$spawnCmd(router),
					commands)));
	});
var $elm$core$Task$onSelfMsg = F3(
	function (_v0, _v1, _v2) {
		return $elm$core$Task$succeed(0);
	});
var $elm$core$Task$cmdMap = F2(
	function (tagger, _v0) {
		var task = _v0;
		return A2($elm$core$Task$map, tagger, task);
	});
_Platform_effectManagers['Task'] = _Platform_createManager($elm$core$Task$init, $elm$core$Task$onEffects, $elm$core$Task$onSelfMsg, $elm$core$Task$cmdMap);
var $elm$core$Task$command = _Platform_leaf('Task');
var $elm$core$Task$perform = F2(
	function (toMessage, task) {
		return $elm$core$Task$command(
			A2($elm$core$Task$map, toMessage, task));
	});
var $elm$browser$Browser$element = _Browser_element;
var $author$project$AppStorage$MapData = F4(
	function (scenarioTitle, roomData, overlays, monsters) {
		return {bn: monsters, bA: overlays, bT: roomData, bZ: scenarioTitle};
	});
var $author$project$BoardHtml$Closed = 1;
var $author$project$Creator$MapTileMenu = 0;
var $author$project$Creator$Model = function (map) {
	return function (currentDraggable) {
		return function (menuOpen) {
			return function (sideMenu) {
				return function (contextMenuState) {
					return function (contextMenuPosition) {
						return function (contextMenuAbsPosition) {
							return function (cachedDoors) {
								return function (cachedObstacles) {
									return function (cachedMisc) {
										return function (cachedRoomCells) {
											return function (errorString) {
												return function (showError) {
													return {aT: cachedDoors, aU: cachedMisc, aV: cachedObstacles, c: cachedRoomCells, at: contextMenuAbsPosition, au: contextMenuPosition, J: contextMenuState, a_: currentDraggable, af: errorString, a: map, M: menuOpen, X: showError, C: sideMenu};
												};
											};
										};
									};
								};
							};
						};
					};
				};
			};
		};
	};
};
var $elm$core$Dict$RBEmpty_elm_builtin = {$: -2};
var $elm$core$Dict$empty = $elm$core$Dict$RBEmpty_elm_builtin;
var $elm$core$Dict$Black = 1;
var $elm$core$Dict$RBNode_elm_builtin = F5(
	function (a, b, c, d, e) {
		return {$: -1, a: a, b: b, c: c, d: d, e: e};
	});
var $elm$core$Dict$Red = 0;
var $elm$core$Dict$balance = F5(
	function (color, key, value, left, right) {
		if ((right.$ === -1) && (!right.a)) {
			var _v1 = right.a;
			var rK = right.b;
			var rV = right.c;
			var rLeft = right.d;
			var rRight = right.e;
			if ((left.$ === -1) && (!left.a)) {
				var _v3 = left.a;
				var lK = left.b;
				var lV = left.c;
				var lLeft = left.d;
				var lRight = left.e;
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					0,
					key,
					value,
					A5($elm$core$Dict$RBNode_elm_builtin, 1, lK, lV, lLeft, lRight),
					A5($elm$core$Dict$RBNode_elm_builtin, 1, rK, rV, rLeft, rRight));
			} else {
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					color,
					rK,
					rV,
					A5($elm$core$Dict$RBNode_elm_builtin, 0, key, value, left, rLeft),
					rRight);
			}
		} else {
			if ((((left.$ === -1) && (!left.a)) && (left.d.$ === -1)) && (!left.d.a)) {
				var _v5 = left.a;
				var lK = left.b;
				var lV = left.c;
				var _v6 = left.d;
				var _v7 = _v6.a;
				var llK = _v6.b;
				var llV = _v6.c;
				var llLeft = _v6.d;
				var llRight = _v6.e;
				var lRight = left.e;
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					0,
					lK,
					lV,
					A5($elm$core$Dict$RBNode_elm_builtin, 1, llK, llV, llLeft, llRight),
					A5($elm$core$Dict$RBNode_elm_builtin, 1, key, value, lRight, right));
			} else {
				return A5($elm$core$Dict$RBNode_elm_builtin, color, key, value, left, right);
			}
		}
	});
var $elm$core$Basics$compare = _Utils_compare;
var $elm$core$Dict$insertHelp = F3(
	function (key, value, dict) {
		if (dict.$ === -2) {
			return A5($elm$core$Dict$RBNode_elm_builtin, 0, key, value, $elm$core$Dict$RBEmpty_elm_builtin, $elm$core$Dict$RBEmpty_elm_builtin);
		} else {
			var nColor = dict.a;
			var nKey = dict.b;
			var nValue = dict.c;
			var nLeft = dict.d;
			var nRight = dict.e;
			var _v1 = A2($elm$core$Basics$compare, key, nKey);
			switch (_v1) {
				case 0:
					return A5(
						$elm$core$Dict$balance,
						nColor,
						nKey,
						nValue,
						A3($elm$core$Dict$insertHelp, key, value, nLeft),
						nRight);
				case 1:
					return A5($elm$core$Dict$RBNode_elm_builtin, nColor, nKey, value, nLeft, nRight);
				default:
					return A5(
						$elm$core$Dict$balance,
						nColor,
						nKey,
						nValue,
						nLeft,
						A3($elm$core$Dict$insertHelp, key, value, nRight));
			}
		}
	});
var $elm$core$Dict$insert = F3(
	function (key, value, dict) {
		var _v0 = A3($elm$core$Dict$insertHelp, key, value, dict);
		if ((_v0.$ === -1) && (!_v0.a)) {
			var _v1 = _v0.a;
			var k = _v0.b;
			var v = _v0.c;
			var l = _v0.d;
			var r = _v0.e;
			return A5($elm$core$Dict$RBNode_elm_builtin, 1, k, v, l, r);
		} else {
			var x = _v0;
			return x;
		}
	});
var $elm$core$Dict$fromList = function (assocs) {
	return A3(
		$elm$core$List$foldl,
		F2(
			function (_v0, dict) {
				var key = _v0.a;
				var value = _v0.b;
				return A3($elm$core$Dict$insert, key, value, dict);
			}),
		$elm$core$Dict$empty,
		assocs);
};
var $elm$core$Basics$ge = _Utils_ge;
var $elm$core$Array$fromListHelp = F3(
	function (list, nodeList, nodeListSize) {
		fromListHelp:
		while (true) {
			var _v0 = A2($elm$core$Elm$JsArray$initializeFromList, $elm$core$Array$branchFactor, list);
			var jsArray = _v0.a;
			var remainingItems = _v0.b;
			if (_Utils_cmp(
				$elm$core$Elm$JsArray$length(jsArray),
				$elm$core$Array$branchFactor) < 0) {
				return A2(
					$elm$core$Array$builderToArray,
					true,
					{h: nodeList, e: nodeListSize, g: jsArray});
			} else {
				var $temp$list = remainingItems,
					$temp$nodeList = A2(
					$elm$core$List$cons,
					$elm$core$Array$Leaf(jsArray),
					nodeList),
					$temp$nodeListSize = nodeListSize + 1;
				list = $temp$list;
				nodeList = $temp$nodeList;
				nodeListSize = $temp$nodeListSize;
				continue fromListHelp;
			}
		}
	});
var $elm$core$Array$fromList = function (list) {
	if (!list.b) {
		return $elm$core$Array$empty;
	} else {
		return A3($elm$core$Array$fromListHelp, list, _List_Nil, 0);
	}
};
var $author$project$BoardMapTile$getGridByRef = function (ref) {
	var configN = _List_fromArray(
		[
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true, true, true, true, true, true])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true, true, true, true, true, false])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true, true, true, true, true, true])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true, true, true, true, true, false])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true, true, true, true, true, true])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true, true, true, true, true, false])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true, true, true, true, true, true]))
		]);
	var configM = _List_fromArray(
		[
			$elm$core$Array$fromList(
			_List_fromArray(
				[false, true, true, true, true, false])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true, true, true, false])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true, true, true, true])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true, true, true, false])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true, true, true, true])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true, true, true, false])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[false, true, true, true, true, false]))
		]);
	var configL = _List_fromArray(
		[
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true, true, true])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true, true, false])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true, true, true])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true, true, false])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true, true, true])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true, true, false])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true, true, true]))
		]);
	var configK = _List_fromArray(
		[
			$elm$core$Array$fromList(
			_List_fromArray(
				[false, false, true, true, true, true, false, false])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[false, true, true, true, true, true, false, false])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[false, true, true, true, true, true, true, false])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true, false, true, true, true, false])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true, false, false, true, true, true])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, false, false, false, true, true, false]))
		]);
	var configJ1bb = _List_fromArray(
		[
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true, true, true, false, false, false])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true, true, false, false, false, false])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true, true, false, false, false, false])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[false, false, false, false, false, false, false, false])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[false, false, false, false, false, false, false, false])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[false, false, false, false, false, false, false, false])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[false, false, false, false, false, false, false, false]))
		]);
	var configJ1ba = _List_fromArray(
		[
			$elm$core$Array$fromList(
			_List_fromArray(
				[false, false, false, false, false, false, false, false])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[false, false, false, false, true, true, false, false])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[false, false, false, false, true, true, true, false])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[false, false, false, false, true, true, true, false])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[false, false, false, false, false, true, true, true])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[false, false, false, false, false, true, false, false])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[false, false, false, false, false, false, false, false]))
		]);
	var configJ = _List_fromArray(
		[
			$elm$core$Array$fromList(
			_List_fromArray(
				[false, false, false, false, false, false, true, false])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[false, false, false, false, false, true, true, true])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[false, false, false, false, false, true, true, true])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[false, false, false, false, true, true, true, false])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true, true, true, true, true, false])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true, true, true, true, false, false])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true, true, true, false, false, false]))
		]);
	var configI = _List_fromArray(
		[
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true, true, true, true])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true, true, true, false])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true, true, true, true])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true, true, true, false])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true, true, true, true]))
		]);
	var configH = _List_fromArray(
		[
			$elm$core$Array$fromList(
			_List_fromArray(
				[false, true, true, true, true, true, true])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true, true, true, true, true])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[false, false, false, true, true, false, false])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[false, false, true, true, true, false, false])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[false, false, false, true, true, false, false])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[false, false, true, true, true, false, false])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[false, false, false, true, true, false, false]))
		]);
	var configG = _List_fromArray(
		[
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true, true, true, true, true, true])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true, true, true, true, true, false])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true, true, true, true, true, true]))
		]);
	var configF = _List_fromArray(
		[
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, false])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, false])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, false])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, false])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true]))
		]);
	var configE = _List_fromArray(
		[
			$elm$core$Array$fromList(
			_List_fromArray(
				[false, true, true, true, true])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true, true, true])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[false, true, true, true, true])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true, true, true])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[false, true, true, true, true]))
		]);
	var configD = _List_fromArray(
		[
			$elm$core$Array$fromList(
			_List_fromArray(
				[false, true, true, true, false])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true, true, false])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true, true, true])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true, true, false])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[false, true, true, true, false]))
		]);
	var configC = _List_fromArray(
		[
			$elm$core$Array$fromList(
			_List_fromArray(
				[false, true, true, false])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true, false])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true, true])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true, false]))
		]);
	var configB = _List_fromArray(
		[
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true, true])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true, false])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true, true])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true, false]))
		]);
	var configA = _List_fromArray(
		[
			$elm$core$Array$fromList(
			_List_fromArray(
				[false, false, false, false, false])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true, true, false])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[true, true, true, true, true])),
			$elm$core$Array$fromList(
			_List_fromArray(
				[false, false, false, false, false]))
		]);
	return $elm$core$Array$fromList(
		function () {
			switch (ref) {
				case 0:
					return configA;
				case 1:
					return configA;
				case 2:
					return configA;
				case 3:
					return configA;
				case 4:
					return configA;
				case 5:
					return configA;
				case 6:
					return configA;
				case 7:
					return configA;
				case 8:
					return configB;
				case 9:
					return configB;
				case 10:
					return configB;
				case 11:
					return configB;
				case 12:
					return configB;
				case 13:
					return configB;
				case 14:
					return configB;
				case 15:
					return configB;
				case 16:
					return configC;
				case 17:
					return configC;
				case 18:
					return configC;
				case 19:
					return configC;
				case 20:
					return configD;
				case 21:
					return configD;
				case 22:
					return configD;
				case 23:
					return configD;
				case 24:
					return configE;
				case 25:
					return configE;
				case 26:
					return configF;
				case 27:
					return configF;
				case 28:
					return configG;
				case 29:
					return configG;
				case 30:
					return configG;
				case 31:
					return configG;
				case 32:
					return configH;
				case 33:
					return configH;
				case 34:
					return configH;
				case 35:
					return configH;
				case 36:
					return configH;
				case 37:
					return configH;
				case 38:
					return configI;
				case 39:
					return configI;
				case 40:
					return configI;
				case 41:
					return configI;
				case 42:
					return configJ;
				case 43:
					return $elm$core$List$reverse(configJ);
				case 44:
					return configJ1ba;
				case 45:
					return configJ1bb;
				case 46:
					return configJ;
				case 47:
					return $elm$core$List$reverse(configJ);
				case 48:
					return configK;
				case 49:
					return configK;
				case 50:
					return configK;
				case 51:
					return configK;
				case 52:
					return configL;
				case 53:
					return configL;
				case 54:
					return configL;
				case 55:
					return configL;
				case 56:
					return configL;
				case 57:
					return configL;
				case 58:
					return configM;
				case 59:
					return configM;
				case 60:
					return configN;
				case 61:
					return configN;
				default:
					return _List_fromArray(
						[
							$elm$core$Array$fromList(
							_List_fromArray(
								[true]))
						]);
			}
		}());
};
var $author$project$Creator$gridSize = 40;
var $elm$core$Elm$JsArray$foldl = _JsArray_foldl;
var $elm$core$Elm$JsArray$indexedMap = _JsArray_indexedMap;
var $elm$core$Bitwise$shiftLeftBy = _Bitwise_shiftLeftBy;
var $elm$core$Bitwise$shiftRightZfBy = _Bitwise_shiftRightZfBy;
var $elm$core$Array$tailIndex = function (len) {
	return (len >>> 5) << 5;
};
var $elm$core$Array$indexedMap = F2(
	function (func, _v0) {
		var len = _v0.a;
		var tree = _v0.c;
		var tail = _v0.d;
		var initialBuilder = {
			h: _List_Nil,
			e: 0,
			g: A3(
				$elm$core$Elm$JsArray$indexedMap,
				func,
				$elm$core$Array$tailIndex(len),
				tail)
		};
		var helper = F2(
			function (node, builder) {
				if (!node.$) {
					var subTree = node.a;
					return A3($elm$core$Elm$JsArray$foldl, helper, builder, subTree);
				} else {
					var leaf = node.a;
					var offset = builder.e * $elm$core$Array$branchFactor;
					var mappedLeaf = $elm$core$Array$Leaf(
						A3($elm$core$Elm$JsArray$indexedMap, func, offset, leaf));
					return {
						h: A2($elm$core$List$cons, mappedLeaf, builder.h),
						e: builder.e + 1,
						g: builder.g
					};
				}
			});
		return A2(
			$elm$core$Array$builderToArray,
			true,
			A3($elm$core$Elm$JsArray$foldl, helper, initialBuilder, tree));
	});
var $elm$core$Basics$min = F2(
	function (x, y) {
		return (_Utils_cmp(x, y) < 0) ? x : y;
	});
var $elm$core$Basics$modBy = _Basics_modBy;
var $elm$core$Basics$negate = function (n) {
	return -n;
};
var $elm$core$Bitwise$and = _Bitwise_and;
var $author$project$Hexagon$cubeToOddRow = function (_v0) {
	var x = _v0.a;
	var z = _v0.c;
	return _Utils_Tuple2(x + (((z - (z & 1)) / 2) | 0), z);
};
var $author$project$Hexagon$oddRowToCube = function (_v0) {
	var x = _v0.a;
	var y = _v0.b;
	var newX = x - (((y - (y & 1)) / 2) | 0);
	return _Utils_Tuple3(newX, (-newX) - y, y);
};
var $author$project$Hexagon$singleRotate = F2(
	function (origin, rotationPoint) {
		var _v0 = $author$project$Hexagon$oddRowToCube(rotationPoint);
		var rotateX = _v0.a;
		var rotateY = _v0.b;
		var rotateZ = _v0.c;
		var _v1 = $author$project$Hexagon$oddRowToCube(origin);
		var originX = _v1.a;
		var originY = _v1.b;
		var originZ = _v1.c;
		var _v2 = _Utils_Tuple3(-(originZ - rotateZ), -(originX - rotateX), -(originY - rotateY));
		var rX = _v2.a;
		var rY = _v2.b;
		var rZ = _v2.c;
		return $author$project$Hexagon$cubeToOddRow(
			_Utils_Tuple3(rX + rotateX, rY + rotateY, rZ + rotateZ));
	});
var $author$project$Hexagon$rotate = F3(
	function (origin, rotationPoint, numTurns) {
		rotate:
		while (true) {
			var rotateResult = A2($author$project$Hexagon$singleRotate, origin, rotationPoint);
			switch (numTurns) {
				case 0:
					return origin;
				case 1:
					return rotateResult;
				default:
					var other = numTurns;
					if (other < 0) {
						var $temp$origin = rotateResult,
							$temp$rotationPoint = rotationPoint,
							$temp$numTurns = other + 1;
						origin = $temp$origin;
						rotationPoint = $temp$rotationPoint;
						numTurns = $temp$numTurns;
						continue rotate;
					} else {
						var $temp$origin = rotateResult,
							$temp$rotationPoint = rotationPoint,
							$temp$numTurns = other - 1;
						origin = $temp$origin;
						rotationPoint = $temp$rotationPoint;
						numTurns = $temp$numTurns;
						continue rotate;
					}
			}
		}
	});
var $author$project$Scenario$normaliseAndRotatePoint = F4(
	function (turns, refPoint, origin, tileCoord) {
		var _v0 = $author$project$Hexagon$oddRowToCube(tileCoord);
		var tileCoordX = _v0.a;
		var tileCoordY = _v0.b;
		var tileCoordZ = _v0.c;
		var _v1 = $author$project$Hexagon$oddRowToCube(refPoint);
		var refPointX = _v1.a;
		var refPointY = _v1.b;
		var refPointZ = _v1.c;
		var _v2 = $author$project$Hexagon$oddRowToCube(origin);
		var originX = _v2.a;
		var originY = _v2.b;
		var originZ = _v2.c;
		var initCoords = $author$project$Hexagon$cubeToOddRow(
			_Utils_Tuple3((tileCoordX - originX) + refPointX, (tileCoordY - originY) + refPointY, (tileCoordZ - originZ) + refPointZ));
		return A3($author$project$Hexagon$rotate, initCoords, refPoint, turns);
	});
var $author$project$Creator$calculateRoomCells = function (room) {
	var cells = $elm$core$Dict$fromList(
		A3(
			$elm$core$Array$foldr,
			F2(
				function (a, b) {
					return _Utils_ap(
						$elm$core$Array$toList(a),
						b);
				}),
			_List_Nil,
			A2(
				$elm$core$Array$indexedMap,
				F2(
					function (y, c) {
						return A2(
							$elm$core$Array$indexedMap,
							F2(
								function (x, p) {
									var cellLoc = function () {
										var _v11 = room.dj;
										var originX = _v11.a;
										var originY = _v11.b;
										var newX = ((A2($elm$core$Basics$modBy, 2, originY) === 1) && (A2($elm$core$Basics$modBy, 2, y) === 1)) ? (x + 1) : x;
										return A4(
											$author$project$Scenario$normaliseAndRotatePoint,
											room.dL,
											room.dj,
											room.dj,
											_Utils_Tuple2(newX + originX, y + originY));
									}();
									return _Utils_Tuple2(
										cellLoc,
										_Utils_Tuple2(
											_Utils_Tuple2(x, y),
											p));
								}),
							c);
					}),
				$author$project$BoardMapTile$getGridByRef(room.bJ))));
	var _v0 = function (_v5) {
		var _v6 = _v5.a;
		var minX = _v6.a;
		var maxX = _v6.b;
		var _v7 = _v5.b;
		var minY = _v7.a;
		var maxY = _v7.b;
		var newY = (minY < 0) ? (-minY) : ((_Utils_cmp(maxY, $author$project$Creator$gridSize) > -1) ? (($author$project$Creator$gridSize - 1) - maxY) : 0);
		var newX = (minX < 0) ? (-minX) : ((_Utils_cmp(maxX, $author$project$Creator$gridSize) > -1) ? (($author$project$Creator$gridSize - 1) - maxX) : 0);
		return _Utils_Tuple2(newX, newY);
	}(
		A3(
			$elm$core$List$foldr,
			F2(
				function (_v1, _v2) {
					var x = _v1.a;
					var y = _v1.b;
					var _v3 = _v2.a;
					var minX = _v3.a;
					var maxX = _v3.b;
					var _v4 = _v2.b;
					var minY = _v4.a;
					var maxY = _v4.b;
					return _Utils_Tuple2(
						_Utils_Tuple2(
							A2($elm$core$Basics$min, x, minX),
							A2($elm$core$Basics$max, x, maxX)),
						_Utils_Tuple2(
							A2($elm$core$Basics$min, y, minY),
							A2($elm$core$Basics$max, y, maxY)));
				}),
			_Utils_Tuple2(
				_Utils_Tuple2(0, 0),
				_Utils_Tuple2(0, 0)),
			$elm$core$Dict$keys(cells)));
	var deltaX = _v0.a;
	var deltaY = _v0.b;
	var newCells = ((!deltaX) && (!deltaY)) ? cells : $elm$core$Dict$fromList(
		A2(
			$elm$core$List$map,
			function (_v9) {
				var _v10 = _v9.a;
				var x = _v10.a;
				var y = _v10.b;
				var v = _v9.b;
				var x1 = ((!A2($elm$core$Basics$modBy, 2, y)) && (A2($elm$core$Basics$modBy, 2, y + deltaY) === 1)) ? (x - 1) : x;
				return _Utils_Tuple2(
					_Utils_Tuple2(x1 + deltaX, y + deltaY),
					v);
			},
			$elm$core$Dict$toList(cells)));
	return _Utils_Tuple2(
		_Utils_Tuple2(room.bJ, newCells),
		function () {
			var _v8 = room.dj;
			var x = _v8.a;
			var y = _v8.b;
			return _Utils_Tuple2(x + deltaX, y + deltaY);
		}());
};
var $elm$core$Dict$foldl = F3(
	function (func, acc, dict) {
		foldl:
		while (true) {
			if (dict.$ === -2) {
				return acc;
			} else {
				var key = dict.b;
				var value = dict.c;
				var left = dict.d;
				var right = dict.e;
				var $temp$func = func,
					$temp$acc = A3(
					func,
					key,
					value,
					A3($elm$core$Dict$foldl, func, acc, left)),
					$temp$dict = right;
				func = $temp$func;
				acc = $temp$acc;
				dict = $temp$dict;
				continue foldl;
			}
		}
	});
var $elm$core$Dict$filter = F2(
	function (isGood, dict) {
		return A3(
			$elm$core$Dict$foldl,
			F3(
				function (k, v, d) {
					return A2(isGood, k, v) ? A3($elm$core$Dict$insert, k, v, d) : d;
				}),
			$elm$core$Dict$empty,
			dict);
	});
var $author$project$BoardOverlay$Altar = 0;
var $author$project$BoardOverlay$AltarDoor = {$: 0};
var $author$project$BoardOverlay$Barrel = 1;
var $author$project$BoardOverlay$BearTrap = 0;
var $author$project$BoardOverlay$Bookcase = 2;
var $author$project$BoardOverlay$Boulder1 = 3;
var $author$project$BoardOverlay$Boulder2 = 4;
var $author$project$BoardOverlay$Boulder3 = 5;
var $author$project$BoardOverlay$BreakableWall = {$: 1};
var $author$project$BoardOverlay$Bush = 6;
var $author$project$BoardOverlay$Cabinet = 7;
var $author$project$BoardOverlay$Chest = function (a) {
	return {$: 0, a: a};
};
var $author$project$BoardOverlay$Coin = function (a) {
	return {$: 1, a: a};
};
var $author$project$BoardOverlay$Corridor = F2(
	function (a, b) {
		return {$: 2, a: a, b: b};
	});
var $author$project$BoardOverlay$Crate = 8;
var $author$project$BoardOverlay$Crystal = 9;
var $author$project$BoardOverlay$Dark = 0;
var $author$project$BoardOverlay$DarkFog = {$: 3};
var $author$project$BoardOverlay$DarkPit = 10;
var $author$project$BoardOverlay$DifficultTerrain = function (a) {
	return {$: 0, a: a};
};
var $author$project$BoardOverlay$Door = F2(
	function (a, b) {
		return {$: 1, a: a, b: b};
	});
var $author$project$BoardOverlay$Earth = 1;
var $author$project$BoardOverlay$Fountain = 11;
var $author$project$BoardOverlay$Hazard = function (a) {
	return {$: 2, a: a};
};
var $author$project$BoardOverlay$HotCoals = 0;
var $author$project$BoardOverlay$HugeRock = 0;
var $author$project$BoardOverlay$Iron = 1;
var $author$project$BoardOverlay$LargeRock = 2;
var $author$project$BoardOverlay$LightFog = {$: 4};
var $author$project$BoardOverlay$Locked = {$: 2};
var $author$project$BoardOverlay$Log = 0;
var $author$project$BoardOverlay$ManmadeStone = 2;
var $author$project$BoardOverlay$Mirror = 12;
var $author$project$BoardOverlay$NaturalStone = 3;
var $author$project$BoardOverlay$Nest = 13;
var $author$project$BoardOverlay$ObsidianGlass = 3;
var $author$project$BoardOverlay$Obstacle = function (a) {
	return {$: 4, a: a};
};
var $author$project$BoardOverlay$One = 0;
var $author$project$BoardOverlay$Pillar = 14;
var $author$project$BoardOverlay$Poison = 1;
var $author$project$BoardOverlay$PressurePlate = 4;
var $author$project$BoardOverlay$Rift = {$: 5};
var $author$project$BoardOverlay$Rock = 4;
var $author$project$BoardOverlay$RockColumn = 15;
var $author$project$BoardOverlay$Rubble = 1;
var $author$project$BoardOverlay$Sarcophagus = 16;
var $author$project$BoardOverlay$Shelf = 17;
var $author$project$BoardOverlay$Spike = 2;
var $author$project$BoardOverlay$Stairs = 2;
var $author$project$BoardOverlay$Stalagmites = 18;
var $author$project$BoardOverlay$StartingLocation = {$: 6};
var $author$project$BoardOverlay$Stone = {$: 5};
var $author$project$BoardOverlay$Stump = 19;
var $author$project$BoardOverlay$Table = 20;
var $author$project$BoardOverlay$Thorns = 1;
var $author$project$BoardOverlay$Token = function (a) {
	return {$: 9, a: a};
};
var $author$project$BoardOverlay$Totem = 21;
var $author$project$BoardOverlay$Trap = function (a) {
	return {$: 7, a: a};
};
var $author$project$BoardOverlay$Treasure = function (a) {
	return {$: 8, a: a};
};
var $author$project$BoardOverlay$Tree3 = 22;
var $author$project$BoardOverlay$Two = 1;
var $author$project$BoardOverlay$VerticalStairs = 3;
var $author$project$BoardOverlay$Wall = function (a) {
	return {$: 10, a: a};
};
var $author$project$BoardOverlay$WallSection = 23;
var $author$project$BoardOverlay$Water = 4;
var $author$project$BoardOverlay$Wood = 5;
var $author$project$BoardOverlay$Wooden = {$: 6};
var $author$project$BoardOverlay$overlayDictionary = $elm$core$Dict$fromList(
	_List_fromArray(
		[
			_Utils_Tuple2(
			'door-altar',
			A2($author$project$BoardOverlay$Door, $author$project$BoardOverlay$AltarDoor, _List_Nil)),
			_Utils_Tuple2(
			'door-stone',
			A2($author$project$BoardOverlay$Door, $author$project$BoardOverlay$Stone, _List_Nil)),
			_Utils_Tuple2(
			'door-wooden',
			A2($author$project$BoardOverlay$Door, $author$project$BoardOverlay$Wooden, _List_Nil)),
			_Utils_Tuple2(
			'door-dark-fog',
			A2($author$project$BoardOverlay$Door, $author$project$BoardOverlay$DarkFog, _List_Nil)),
			_Utils_Tuple2(
			'door-light-fog',
			A2($author$project$BoardOverlay$Door, $author$project$BoardOverlay$LightFog, _List_Nil)),
			_Utils_Tuple2(
			'door-breakable-wall',
			A2($author$project$BoardOverlay$Door, $author$project$BoardOverlay$BreakableWall, _List_Nil)),
			_Utils_Tuple2(
			'corridor-dark-1',
			A2(
				$author$project$BoardOverlay$Door,
				A2($author$project$BoardOverlay$Corridor, 0, 0),
				_List_Nil)),
			_Utils_Tuple2(
			'corridor-earth-1',
			A2(
				$author$project$BoardOverlay$Door,
				A2($author$project$BoardOverlay$Corridor, 1, 0),
				_List_Nil)),
			_Utils_Tuple2(
			'corridor-manmade-stone-1',
			A2(
				$author$project$BoardOverlay$Door,
				A2($author$project$BoardOverlay$Corridor, 2, 0),
				_List_Nil)),
			_Utils_Tuple2(
			'corridor-natural-stone-1',
			A2(
				$author$project$BoardOverlay$Door,
				A2($author$project$BoardOverlay$Corridor, 3, 0),
				_List_Nil)),
			_Utils_Tuple2(
			'corridor-pressure-plate-1',
			A2(
				$author$project$BoardOverlay$Door,
				A2($author$project$BoardOverlay$Corridor, 4, 0),
				_List_Nil)),
			_Utils_Tuple2(
			'corridor-wood-1',
			A2(
				$author$project$BoardOverlay$Door,
				A2($author$project$BoardOverlay$Corridor, 5, 0),
				_List_Nil)),
			_Utils_Tuple2(
			'corridor-dark-2',
			A2(
				$author$project$BoardOverlay$Door,
				A2($author$project$BoardOverlay$Corridor, 0, 1),
				_List_Nil)),
			_Utils_Tuple2(
			'corridor-earth-2',
			A2(
				$author$project$BoardOverlay$Door,
				A2($author$project$BoardOverlay$Corridor, 1, 1),
				_List_Nil)),
			_Utils_Tuple2(
			'corridor-manmade-stone-2',
			A2(
				$author$project$BoardOverlay$Door,
				A2($author$project$BoardOverlay$Corridor, 2, 1),
				_List_Nil)),
			_Utils_Tuple2(
			'corridor-natural-stone-2',
			A2(
				$author$project$BoardOverlay$Door,
				A2($author$project$BoardOverlay$Corridor, 3, 1),
				_List_Nil)),
			_Utils_Tuple2(
			'corridor-wood-2',
			A2(
				$author$project$BoardOverlay$Door,
				A2($author$project$BoardOverlay$Corridor, 5, 1),
				_List_Nil)),
			_Utils_Tuple2(
			'difficult-terrain-log',
			$author$project$BoardOverlay$DifficultTerrain(0)),
			_Utils_Tuple2(
			'difficult-terrain-rubble',
			$author$project$BoardOverlay$DifficultTerrain(1)),
			_Utils_Tuple2(
			'difficult-terrain-stairs',
			$author$project$BoardOverlay$DifficultTerrain(2)),
			_Utils_Tuple2(
			'difficult-terrain-stairs-vert',
			$author$project$BoardOverlay$DifficultTerrain(3)),
			_Utils_Tuple2(
			'difficult-terrain-water',
			$author$project$BoardOverlay$DifficultTerrain(4)),
			_Utils_Tuple2(
			'hazard-hot-coals',
			$author$project$BoardOverlay$Hazard(0)),
			_Utils_Tuple2(
			'hazard-thorns',
			$author$project$BoardOverlay$Hazard(1)),
			_Utils_Tuple2(
			'obstacle-altar',
			$author$project$BoardOverlay$Obstacle(0)),
			_Utils_Tuple2(
			'obstacle-barrel',
			$author$project$BoardOverlay$Obstacle(1)),
			_Utils_Tuple2(
			'obstacle-bookcase',
			$author$project$BoardOverlay$Obstacle(2)),
			_Utils_Tuple2(
			'obstacle-boulder-1',
			$author$project$BoardOverlay$Obstacle(3)),
			_Utils_Tuple2(
			'obstacle-boulder-2',
			$author$project$BoardOverlay$Obstacle(4)),
			_Utils_Tuple2(
			'obstacle-boulder-3',
			$author$project$BoardOverlay$Obstacle(5)),
			_Utils_Tuple2(
			'obstacle-bush',
			$author$project$BoardOverlay$Obstacle(6)),
			_Utils_Tuple2(
			'obstacle-cabinet',
			$author$project$BoardOverlay$Obstacle(7)),
			_Utils_Tuple2(
			'obstacle-crate',
			$author$project$BoardOverlay$Obstacle(8)),
			_Utils_Tuple2(
			'obstacle-crystal',
			$author$project$BoardOverlay$Obstacle(9)),
			_Utils_Tuple2(
			'obstacle-dark-pit',
			$author$project$BoardOverlay$Obstacle(10)),
			_Utils_Tuple2(
			'obstacle-fountain',
			$author$project$BoardOverlay$Obstacle(11)),
			_Utils_Tuple2(
			'obstacle-mirror',
			$author$project$BoardOverlay$Obstacle(12)),
			_Utils_Tuple2(
			'obstacle-nest',
			$author$project$BoardOverlay$Obstacle(13)),
			_Utils_Tuple2(
			'obstacle-pillar',
			$author$project$BoardOverlay$Obstacle(14)),
			_Utils_Tuple2(
			'obstacle-rock-column',
			$author$project$BoardOverlay$Obstacle(15)),
			_Utils_Tuple2(
			'obstacle-sarcophagus',
			$author$project$BoardOverlay$Obstacle(16)),
			_Utils_Tuple2(
			'obstacle-shelf',
			$author$project$BoardOverlay$Obstacle(17)),
			_Utils_Tuple2(
			'obstacle-stalagmites',
			$author$project$BoardOverlay$Obstacle(18)),
			_Utils_Tuple2(
			'obstacle-stump',
			$author$project$BoardOverlay$Obstacle(19)),
			_Utils_Tuple2(
			'obstacle-table',
			$author$project$BoardOverlay$Obstacle(20)),
			_Utils_Tuple2(
			'obstacle-totem',
			$author$project$BoardOverlay$Obstacle(21)),
			_Utils_Tuple2(
			'obstacle-tree-3',
			$author$project$BoardOverlay$Obstacle(22)),
			_Utils_Tuple2(
			'obstacle-wall-section',
			$author$project$BoardOverlay$Obstacle(23)),
			_Utils_Tuple2('rift', $author$project$BoardOverlay$Rift),
			_Utils_Tuple2('starting-location', $author$project$BoardOverlay$StartingLocation),
			_Utils_Tuple2(
			'token-a',
			$author$project$BoardOverlay$Token('a')),
			_Utils_Tuple2(
			'token-b',
			$author$project$BoardOverlay$Token('b')),
			_Utils_Tuple2(
			'token-c',
			$author$project$BoardOverlay$Token('c')),
			_Utils_Tuple2(
			'token-d',
			$author$project$BoardOverlay$Token('d')),
			_Utils_Tuple2(
			'token-e',
			$author$project$BoardOverlay$Token('e')),
			_Utils_Tuple2(
			'token-f',
			$author$project$BoardOverlay$Token('f')),
			_Utils_Tuple2(
			'token-1',
			$author$project$BoardOverlay$Token('1')),
			_Utils_Tuple2(
			'token-2',
			$author$project$BoardOverlay$Token('2')),
			_Utils_Tuple2(
			'token-3',
			$author$project$BoardOverlay$Token('3')),
			_Utils_Tuple2(
			'token-4',
			$author$project$BoardOverlay$Token('4')),
			_Utils_Tuple2(
			'token-5',
			$author$project$BoardOverlay$Token('5')),
			_Utils_Tuple2(
			'token-6',
			$author$project$BoardOverlay$Token('6')),
			_Utils_Tuple2(
			'trap-bear',
			$author$project$BoardOverlay$Trap(0)),
			_Utils_Tuple2(
			'trap-spike',
			$author$project$BoardOverlay$Trap(2)),
			_Utils_Tuple2(
			'trap-poison',
			$author$project$BoardOverlay$Trap(1)),
			_Utils_Tuple2(
			'treasure-chest',
			$author$project$BoardOverlay$Treasure(
				$author$project$BoardOverlay$Chest($author$project$BoardOverlay$Locked))),
			_Utils_Tuple2(
			'treasure-coin',
			$author$project$BoardOverlay$Treasure(
				$author$project$BoardOverlay$Coin(0))),
			_Utils_Tuple2(
			'wall-huge-rock',
			$author$project$BoardOverlay$Wall(0)),
			_Utils_Tuple2(
			'wall-iron',
			$author$project$BoardOverlay$Wall(1)),
			_Utils_Tuple2(
			'wall-large-rock',
			$author$project$BoardOverlay$Wall(2)),
			_Utils_Tuple2(
			'wall-obsidian-glass',
			$author$project$BoardOverlay$Wall(3)),
			_Utils_Tuple2(
			'wall-rock',
			$author$project$BoardOverlay$Wall(4))
		]));
var $author$project$BoardOverlay$getOverlayTypesWithLabel = $author$project$BoardOverlay$overlayDictionary;
var $elm$core$List$sortBy = _List_sortBy;
var $author$project$Creator$initModel = function (mapData) {
	var cachedRoomData = A2(
		$elm$core$List$map,
		function (r) {
			var _v12 = $author$project$Creator$calculateRoomCells(r.a$);
			var d = _v12.a;
			return d;
		},
		mapData.bT);
	var _v0 = A3(
		$elm$core$List$foldr,
		F2(
			function (_v9, _v10) {
				var k = _v9.a;
				var v = _v9.b;
				var d = _v10.a;
				var o = _v10.b;
				var m = _v10.c;
				switch (v.$) {
					case 1:
						return _Utils_Tuple3(
							A2($elm$core$List$cons, k, d),
							o,
							m);
					case 4:
						return _Utils_Tuple3(
							d,
							A2($elm$core$List$cons, k, o),
							m);
					default:
						return _Utils_Tuple3(
							d,
							o,
							A2($elm$core$List$cons, k, m));
				}
			}),
		_Utils_Tuple3(_List_Nil, _List_Nil, _List_Nil),
		A2(
			$elm$core$List$sortBy,
			function (_v7) {
				var v = _v7.b;
				switch (v.$) {
					case 6:
						return 0;
					case 9:
						return 2;
					default:
						return 1;
				}
			},
			$elm$core$Dict$toList(
				A2(
					$elm$core$Dict$filter,
					F2(
						function (_v1, v) {
							_v2$5:
							while (true) {
								switch (v.$) {
									case 1:
										switch (v.a.$) {
											case 2:
												if (v.a.b === 1) {
													var _v3 = v.a;
													var _v4 = _v3.b;
													return false;
												} else {
													break _v2$5;
												}
											case 0:
												var _v5 = v.a;
												return false;
											case 1:
												var _v6 = v.a;
												return false;
											default:
												break _v2$5;
										}
									case 5:
										return false;
									case 8:
										if (v.a.$ === 1) {
											return false;
										} else {
											break _v2$5;
										}
									default:
										break _v2$5;
								}
							}
							return true;
						}),
					$author$project$BoardOverlay$getOverlayTypesWithLabel))));
	var doors = _v0.a;
	var obstacles = _v0.b;
	var misc = _v0.c;
	return $author$project$Creator$Model(mapData)($elm$core$Maybe$Nothing)(false)(0)(1)(
		_Utils_Tuple2(0, 0))(
		_Utils_Tuple2(0, 0))(doors)(obstacles)(misc)(cachedRoomData)('')(false);
};
var $elm$json$Json$Decode$decodeValue = _Json_run;
var $author$project$BoardOverlay$BoardOverlay = F4(
	function (ref, id, direction, cells) {
		return {S: cells, aw: direction, ag: id, bJ: ref};
	});
var $elm$json$Json$Decode$andThen = _Json_andThen;
var $author$project$BoardOverlay$Default = 0;
var $author$project$BoardOverlay$DiagonalLeft = 4;
var $author$project$BoardOverlay$DiagonalLeftReverse = 6;
var $author$project$BoardOverlay$DiagonalRight = 5;
var $author$project$BoardOverlay$DiagonalRightReverse = 7;
var $author$project$BoardOverlay$Horizontal = 1;
var $author$project$BoardOverlay$Vertical = 2;
var $author$project$BoardOverlay$VerticalReverse = 3;
var $elm$json$Json$Decode$fail = _Json_fail;
var $elm$core$String$toLower = _String_toLower;
var $author$project$SharedSync$decodeBoardOverlayDirection = function (dir) {
	var _v0 = $elm$core$String$toLower(dir);
	switch (_v0) {
		case 'default':
			return $elm$json$Json$Decode$succeed(0);
		case 'horizontal':
			return $elm$json$Json$Decode$succeed(1);
		case 'vertical':
			return $elm$json$Json$Decode$succeed(2);
		case 'vertical-reverse':
			return $elm$json$Json$Decode$succeed(3);
		case 'diagonal-left':
			return $elm$json$Json$Decode$succeed(4);
		case 'diagonal-right':
			return $elm$json$Json$Decode$succeed(5);
		case 'diagonal-left-reverse':
			return $elm$json$Json$Decode$succeed(6);
		case 'diagonal-right-reverse':
			return $elm$json$Json$Decode$succeed(7);
		default:
			return $elm$json$Json$Decode$fail('Could not decode overlay direction \'' + (dir + '\''));
	}
};
var $author$project$BoardOverlay$Highlight = function (a) {
	return {$: 3, a: a};
};
var $elm$json$Json$Decode$field = _Json_decodeField;
var $elm$json$Json$Decode$string = _Json_decodeString;
var $author$project$SharedSync$decodeDifficultTerrain = A2(
	$elm$json$Json$Decode$andThen,
	function (s) {
		var _v0 = $elm$core$String$toLower(s);
		switch (_v0) {
			case 'log':
				return $elm$json$Json$Decode$succeed(
					$author$project$BoardOverlay$DifficultTerrain(0));
			case 'rubble':
				return $elm$json$Json$Decode$succeed(
					$author$project$BoardOverlay$DifficultTerrain(1));
			case 'stairs':
				return $elm$json$Json$Decode$succeed(
					$author$project$BoardOverlay$DifficultTerrain(2));
			case 'stairs-vert':
				return $elm$json$Json$Decode$succeed(
					$author$project$BoardOverlay$DifficultTerrain(3));
			case 'water':
				return $elm$json$Json$Decode$succeed(
					$author$project$BoardOverlay$DifficultTerrain(4));
			default:
				return $elm$json$Json$Decode$fail(s + ' is not a difficult terrain sub-type');
		}
	},
	A2($elm$json$Json$Decode$field, 'subType', $elm$json$Json$Decode$string));
var $elm$json$Json$Decode$int = _Json_decodeInt;
var $author$project$SharedSync$decodeCorridorSize = function (material) {
	return A2(
		$elm$json$Json$Decode$andThen,
		function (s) {
			switch (s) {
				case 1:
					return $elm$json$Json$Decode$succeed(
						A2($author$project$BoardOverlay$Corridor, material, 0));
				case 2:
					return $elm$json$Json$Decode$succeed(
						A2($author$project$BoardOverlay$Corridor, material, 1));
				default:
					return $elm$json$Json$Decode$fail(
						$elm$core$String$fromInt(s) + ' is not a valid corridor size');
			}
		},
		A2($elm$json$Json$Decode$field, 'size', $elm$json$Json$Decode$int));
};
var $author$project$SharedSync$decodeCorridor = A2(
	$elm$json$Json$Decode$andThen,
	function (m) {
		var material = function () {
			var _v1 = $elm$core$String$toLower(m);
			switch (_v1) {
				case 'dark':
					return $elm$core$Maybe$Just(0);
				case 'earth':
					return $elm$core$Maybe$Just(1);
				case 'manmade-stone':
					return $elm$core$Maybe$Just(2);
				case 'natural-stone':
					return $elm$core$Maybe$Just(3);
				case 'pressure-plate':
					return $elm$core$Maybe$Just(4);
				case 'wood':
					return $elm$core$Maybe$Just(5);
				default:
					return $elm$core$Maybe$Nothing;
			}
		}();
		if (!material.$) {
			var mm = material.a;
			return $author$project$SharedSync$decodeCorridorSize(mm);
		} else {
			return $elm$json$Json$Decode$fail('Could not decode material \'' + (m + '\''));
		}
	},
	A2($elm$json$Json$Decode$field, 'material', $elm$json$Json$Decode$string));
var $author$project$SharedSync$decodeDoor = A2(
	$elm$json$Json$Decode$andThen,
	function (s) {
		var _v0 = $elm$core$String$toLower(s);
		switch (_v0) {
			case 'altar':
				return $elm$json$Json$Decode$succeed($author$project$BoardOverlay$AltarDoor);
			case 'stone':
				return $elm$json$Json$Decode$succeed($author$project$BoardOverlay$Stone);
			case 'wooden':
				return $elm$json$Json$Decode$succeed($author$project$BoardOverlay$Wooden);
			case 'breakable-wall':
				return $elm$json$Json$Decode$succeed($author$project$BoardOverlay$BreakableWall);
			case 'corridor':
				return $author$project$SharedSync$decodeCorridor;
			case 'dark-fog':
				return $elm$json$Json$Decode$succeed($author$project$BoardOverlay$DarkFog);
			case 'light-fog':
				return $elm$json$Json$Decode$succeed($author$project$BoardOverlay$LightFog);
			default:
				return $elm$json$Json$Decode$fail(s + ' is not a door sub-type');
		}
	},
	A2($elm$json$Json$Decode$field, 'subType', $elm$json$Json$Decode$string));
var $author$project$BoardMapTile$A1a = 0;
var $elm$core$List$any = F2(
	function (isOkay, list) {
		any:
		while (true) {
			if (!list.b) {
				return false;
			} else {
				var x = list.a;
				var xs = list.b;
				if (isOkay(x)) {
					return true;
				} else {
					var $temp$isOkay = isOkay,
						$temp$list = xs;
					isOkay = $temp$isOkay;
					list = $temp$list;
					continue any;
				}
			}
		}
	});
var $elm$core$Basics$composeL = F3(
	function (g, f, x) {
		return g(
			f(x));
	});
var $elm$core$Basics$not = _Basics_not;
var $elm$core$List$all = F2(
	function (isOkay, list) {
		return !A2(
			$elm$core$List$any,
			A2($elm$core$Basics$composeL, $elm$core$Basics$not, isOkay),
			list);
	});
var $elm$core$Basics$neq = _Utils_notEqual;
var $author$project$BoardMapTile$A1b = 1;
var $author$project$BoardMapTile$A2a = 2;
var $author$project$BoardMapTile$A2b = 3;
var $author$project$BoardMapTile$A3a = 4;
var $author$project$BoardMapTile$A3b = 5;
var $author$project$BoardMapTile$A4a = 6;
var $author$project$BoardMapTile$A4b = 7;
var $author$project$BoardMapTile$B1a = 8;
var $author$project$BoardMapTile$B1b = 9;
var $author$project$BoardMapTile$B2a = 10;
var $author$project$BoardMapTile$B2b = 11;
var $author$project$BoardMapTile$B3a = 12;
var $author$project$BoardMapTile$B3b = 13;
var $author$project$BoardMapTile$B4a = 14;
var $author$project$BoardMapTile$B4b = 15;
var $author$project$BoardMapTile$C1a = 16;
var $author$project$BoardMapTile$C1b = 17;
var $author$project$BoardMapTile$C2a = 18;
var $author$project$BoardMapTile$C2b = 19;
var $author$project$BoardMapTile$D1a = 20;
var $author$project$BoardMapTile$D1b = 21;
var $author$project$BoardMapTile$D2a = 22;
var $author$project$BoardMapTile$D2b = 23;
var $author$project$BoardMapTile$E1a = 24;
var $author$project$BoardMapTile$E1b = 25;
var $author$project$BoardMapTile$Empty = 62;
var $author$project$BoardMapTile$F1a = 26;
var $author$project$BoardMapTile$F1b = 27;
var $author$project$BoardMapTile$G1a = 28;
var $author$project$BoardMapTile$G1b = 29;
var $author$project$BoardMapTile$G2a = 30;
var $author$project$BoardMapTile$G2b = 31;
var $author$project$BoardMapTile$H1a = 32;
var $author$project$BoardMapTile$H1b = 33;
var $author$project$BoardMapTile$H2a = 34;
var $author$project$BoardMapTile$H2b = 35;
var $author$project$BoardMapTile$H3a = 36;
var $author$project$BoardMapTile$H3b = 37;
var $author$project$BoardMapTile$I1a = 38;
var $author$project$BoardMapTile$I1b = 39;
var $author$project$BoardMapTile$I2a = 40;
var $author$project$BoardMapTile$I2b = 41;
var $author$project$BoardMapTile$J1a = 42;
var $author$project$BoardMapTile$J1b = 43;
var $author$project$BoardMapTile$J1ba = 44;
var $author$project$BoardMapTile$J1bb = 45;
var $author$project$BoardMapTile$J2a = 46;
var $author$project$BoardMapTile$J2b = 47;
var $author$project$BoardMapTile$K1a = 48;
var $author$project$BoardMapTile$K1b = 49;
var $author$project$BoardMapTile$K2a = 50;
var $author$project$BoardMapTile$K2b = 51;
var $author$project$BoardMapTile$L1a = 52;
var $author$project$BoardMapTile$L1b = 53;
var $author$project$BoardMapTile$L2a = 54;
var $author$project$BoardMapTile$L2b = 55;
var $author$project$BoardMapTile$L3a = 56;
var $author$project$BoardMapTile$L3b = 57;
var $author$project$BoardMapTile$M1a = 58;
var $author$project$BoardMapTile$M1b = 59;
var $author$project$BoardMapTile$N1a = 60;
var $author$project$BoardMapTile$N1b = 61;
var $author$project$BoardMapTile$boardRefDict = $elm$core$Dict$fromList(
	_List_fromArray(
		[
			_Utils_Tuple2('a1a', 0),
			_Utils_Tuple2('a1b', 1),
			_Utils_Tuple2('a2a', 2),
			_Utils_Tuple2('a2b', 3),
			_Utils_Tuple2('a3a', 4),
			_Utils_Tuple2('a3b', 5),
			_Utils_Tuple2('a4a', 6),
			_Utils_Tuple2('a4b', 7),
			_Utils_Tuple2('b1a', 8),
			_Utils_Tuple2('b1b', 9),
			_Utils_Tuple2('b2a', 10),
			_Utils_Tuple2('b2b', 11),
			_Utils_Tuple2('b3a', 12),
			_Utils_Tuple2('b3b', 13),
			_Utils_Tuple2('b4a', 14),
			_Utils_Tuple2('b4b', 15),
			_Utils_Tuple2('c1a', 16),
			_Utils_Tuple2('c1b', 17),
			_Utils_Tuple2('c2a', 18),
			_Utils_Tuple2('c2b', 19),
			_Utils_Tuple2('d1a', 20),
			_Utils_Tuple2('d1b', 21),
			_Utils_Tuple2('d2a', 22),
			_Utils_Tuple2('d2b', 23),
			_Utils_Tuple2('e1a', 24),
			_Utils_Tuple2('e1b', 25),
			_Utils_Tuple2('f1a', 26),
			_Utils_Tuple2('f1b', 27),
			_Utils_Tuple2('g1a', 28),
			_Utils_Tuple2('g1b', 29),
			_Utils_Tuple2('g2a', 30),
			_Utils_Tuple2('g2b', 31),
			_Utils_Tuple2('h1a', 32),
			_Utils_Tuple2('h1b', 33),
			_Utils_Tuple2('h2a', 34),
			_Utils_Tuple2('h2b', 35),
			_Utils_Tuple2('h3a', 36),
			_Utils_Tuple2('h3b', 37),
			_Utils_Tuple2('i1a', 38),
			_Utils_Tuple2('i1b', 39),
			_Utils_Tuple2('i2a', 40),
			_Utils_Tuple2('i2b', 41),
			_Utils_Tuple2('j1a', 42),
			_Utils_Tuple2('j1b', 43),
			_Utils_Tuple2('j1ba', 44),
			_Utils_Tuple2('j1bb', 45),
			_Utils_Tuple2('j2a', 46),
			_Utils_Tuple2('j2b', 47),
			_Utils_Tuple2('k1a', 48),
			_Utils_Tuple2('k1b', 49),
			_Utils_Tuple2('k2a', 50),
			_Utils_Tuple2('k2b', 51),
			_Utils_Tuple2('l1a', 52),
			_Utils_Tuple2('l1b', 53),
			_Utils_Tuple2('l2a', 54),
			_Utils_Tuple2('l2b', 55),
			_Utils_Tuple2('l3a', 56),
			_Utils_Tuple2('l3b', 57),
			_Utils_Tuple2('m1a', 58),
			_Utils_Tuple2('m1b', 59),
			_Utils_Tuple2('n1a', 60),
			_Utils_Tuple2('n1b', 61),
			_Utils_Tuple2('empty', 62)
		]));
var $elm$core$Dict$get = F2(
	function (targetKey, dict) {
		get:
		while (true) {
			if (dict.$ === -2) {
				return $elm$core$Maybe$Nothing;
			} else {
				var key = dict.b;
				var value = dict.c;
				var left = dict.d;
				var right = dict.e;
				var _v1 = A2($elm$core$Basics$compare, targetKey, key);
				switch (_v1) {
					case 0:
						var $temp$targetKey = targetKey,
							$temp$dict = left;
						targetKey = $temp$targetKey;
						dict = $temp$dict;
						continue get;
					case 1:
						return $elm$core$Maybe$Just(value);
					default:
						var $temp$targetKey = targetKey,
							$temp$dict = right;
						targetKey = $temp$targetKey;
						dict = $temp$dict;
						continue get;
				}
			}
		}
	});
var $author$project$BoardMapTile$stringToRef = function (ref) {
	return A2(
		$elm$core$Dict$get,
		$elm$core$String$toLower(ref),
		$author$project$BoardMapTile$boardRefDict);
};
var $elm$core$Maybe$withDefault = F2(
	function (_default, maybe) {
		if (!maybe.$) {
			var value = maybe.a;
			return value;
		} else {
			return _default;
		}
	});
var $author$project$SharedSync$decodeMapRefList = function (refs) {
	var decodedRefs = A2(
		$elm$core$List$map,
		function (ref) {
			return $author$project$BoardMapTile$stringToRef(ref);
		},
		refs);
	return A2(
		$elm$core$List$all,
		function (s) {
			return !_Utils_eq(s, $elm$core$Maybe$Nothing);
		},
		decodedRefs) ? $elm$json$Json$Decode$succeed(
		A2(
			$elm$core$List$map,
			function (r) {
				return A2($elm$core$Maybe$withDefault, 0, r);
			},
			decodedRefs)) : $elm$json$Json$Decode$fail('Could not decode all map tile references');
};
var $elm$json$Json$Decode$list = _Json_decodeList;
var $author$project$SharedSync$decodeDoorRefs = function (subType) {
	return A2(
		$elm$json$Json$Decode$andThen,
		function (refs) {
			return $elm$json$Json$Decode$succeed(
				A2($author$project$BoardOverlay$Door, subType, refs));
		},
		A2(
			$elm$json$Json$Decode$andThen,
			$author$project$SharedSync$decodeMapRefList,
			A2(
				$elm$json$Json$Decode$field,
				'links',
				$elm$json$Json$Decode$list($elm$json$Json$Decode$string))));
};
var $author$project$SharedSync$decodeHazard = A2(
	$elm$json$Json$Decode$andThen,
	function (s) {
		var _v0 = $elm$core$String$toLower(s);
		switch (_v0) {
			case 'hot-coals':
				return $elm$json$Json$Decode$succeed(
					$author$project$BoardOverlay$Hazard(0));
			case 'thorns':
				return $elm$json$Json$Decode$succeed(
					$author$project$BoardOverlay$Hazard(1));
			default:
				return $elm$json$Json$Decode$fail(s + ' is not an hazard sub-type');
		}
	},
	A2($elm$json$Json$Decode$field, 'subType', $elm$json$Json$Decode$string));
var $author$project$SharedSync$decodeObstacle = A2(
	$elm$json$Json$Decode$andThen,
	function (s) {
		var _v0 = $elm$core$String$toLower(s);
		switch (_v0) {
			case 'altar':
				return $elm$json$Json$Decode$succeed(
					$author$project$BoardOverlay$Obstacle(0));
			case 'barrel':
				return $elm$json$Json$Decode$succeed(
					$author$project$BoardOverlay$Obstacle(1));
			case 'boulder-1':
				return $elm$json$Json$Decode$succeed(
					$author$project$BoardOverlay$Obstacle(3));
			case 'boulder-2':
				return $elm$json$Json$Decode$succeed(
					$author$project$BoardOverlay$Obstacle(4));
			case 'boulder-3':
				return $elm$json$Json$Decode$succeed(
					$author$project$BoardOverlay$Obstacle(5));
			case 'bush':
				return $elm$json$Json$Decode$succeed(
					$author$project$BoardOverlay$Obstacle(6));
			case 'bookcase':
				return $elm$json$Json$Decode$succeed(
					$author$project$BoardOverlay$Obstacle(2));
			case 'crate':
				return $elm$json$Json$Decode$succeed(
					$author$project$BoardOverlay$Obstacle(8));
			case 'cabinet':
				return $elm$json$Json$Decode$succeed(
					$author$project$BoardOverlay$Obstacle(7));
			case 'crystal':
				return $elm$json$Json$Decode$succeed(
					$author$project$BoardOverlay$Obstacle(9));
			case 'dark-pit':
				return $elm$json$Json$Decode$succeed(
					$author$project$BoardOverlay$Obstacle(10));
			case 'fountain':
				return $elm$json$Json$Decode$succeed(
					$author$project$BoardOverlay$Obstacle(11));
			case 'mirror':
				return $elm$json$Json$Decode$succeed(
					$author$project$BoardOverlay$Obstacle(12));
			case 'nest':
				return $elm$json$Json$Decode$succeed(
					$author$project$BoardOverlay$Obstacle(13));
			case 'pillar':
				return $elm$json$Json$Decode$succeed(
					$author$project$BoardOverlay$Obstacle(14));
			case 'rock-column':
				return $elm$json$Json$Decode$succeed(
					$author$project$BoardOverlay$Obstacle(15));
			case 'sarcophagus':
				return $elm$json$Json$Decode$succeed(
					$author$project$BoardOverlay$Obstacle(16));
			case 'shelf':
				return $elm$json$Json$Decode$succeed(
					$author$project$BoardOverlay$Obstacle(17));
			case 'stalagmites':
				return $elm$json$Json$Decode$succeed(
					$author$project$BoardOverlay$Obstacle(18));
			case 'stump':
				return $elm$json$Json$Decode$succeed(
					$author$project$BoardOverlay$Obstacle(19));
			case 'table':
				return $elm$json$Json$Decode$succeed(
					$author$project$BoardOverlay$Obstacle(20));
			case 'totem':
				return $elm$json$Json$Decode$succeed(
					$author$project$BoardOverlay$Obstacle(21));
			case 'tree-3':
				return $elm$json$Json$Decode$succeed(
					$author$project$BoardOverlay$Obstacle(22));
			case 'wall-section':
				return $elm$json$Json$Decode$succeed(
					$author$project$BoardOverlay$Obstacle(23));
			default:
				return $elm$json$Json$Decode$fail(s + ' is not an obstacle sub-type');
		}
	},
	A2($elm$json$Json$Decode$field, 'subType', $elm$json$Json$Decode$string));
var $author$project$SharedSync$decodeToken = A2(
	$elm$json$Json$Decode$andThen,
	function (s) {
		return $elm$json$Json$Decode$succeed(
			$author$project$BoardOverlay$Token(s));
	},
	A2($elm$json$Json$Decode$field, 'value', $elm$json$Json$Decode$string));
var $author$project$SharedSync$decodeTrap = A2(
	$elm$json$Json$Decode$andThen,
	function (s) {
		var _v0 = $elm$core$String$toLower(s);
		switch (_v0) {
			case 'bear':
				return $elm$json$Json$Decode$succeed(
					$author$project$BoardOverlay$Trap(0));
			case 'spike':
				return $elm$json$Json$Decode$succeed(
					$author$project$BoardOverlay$Trap(2));
			case 'poison':
				return $elm$json$Json$Decode$succeed(
					$author$project$BoardOverlay$Trap(1));
			default:
				return $elm$json$Json$Decode$fail(s + ' is not a trap sub-type');
		}
	},
	A2($elm$json$Json$Decode$field, 'subType', $elm$json$Json$Decode$string));
var $author$project$BoardOverlay$Goal = {$: 1};
var $author$project$BoardOverlay$NormalChest = function (a) {
	return {$: 0, a: a};
};
var $author$project$SharedSync$decodeTreasureChest = A2(
	$elm$json$Json$Decode$andThen,
	function (s) {
		var _v0 = $elm$core$String$toLower(s);
		switch (_v0) {
			case 'goal':
				return $elm$json$Json$Decode$succeed(
					$author$project$BoardOverlay$Treasure(
						$author$project$BoardOverlay$Chest($author$project$BoardOverlay$Goal)));
			case 'locked':
				return $elm$json$Json$Decode$succeed(
					$author$project$BoardOverlay$Treasure(
						$author$project$BoardOverlay$Chest($author$project$BoardOverlay$Locked)));
			default:
				var _v1 = $elm$core$String$toInt(s);
				if (!_v1.$) {
					var i = _v1.a;
					return $elm$json$Json$Decode$succeed(
						$author$project$BoardOverlay$Treasure(
							$author$project$BoardOverlay$Chest(
								$author$project$BoardOverlay$NormalChest(i))));
				} else {
					return $elm$json$Json$Decode$fail('Unknown treasure id \'' + (s + '\'. Valid types are \'goal\' or an Int'));
				}
		}
	},
	A2($elm$json$Json$Decode$field, 'id', $elm$json$Json$Decode$string));
var $author$project$SharedSync$decodeTreasureCoin = A2(
	$elm$json$Json$Decode$andThen,
	function (i) {
		return $elm$json$Json$Decode$succeed(
			$author$project$BoardOverlay$Treasure(
				$author$project$BoardOverlay$Coin(i)));
	},
	A2($elm$json$Json$Decode$field, 'amount', $elm$json$Json$Decode$int));
var $author$project$SharedSync$decodeTreasure = function () {
	var decodeType = function (typeName) {
		var _v0 = $elm$core$String$toLower(typeName);
		switch (_v0) {
			case 'chest':
				return $author$project$SharedSync$decodeTreasureChest;
			case 'coin':
				return $author$project$SharedSync$decodeTreasureCoin;
			default:
				return $elm$json$Json$Decode$fail('Unknown treasure type: ' + typeName);
		}
	};
	return A2(
		$elm$json$Json$Decode$andThen,
		decodeType,
		A2($elm$json$Json$Decode$field, 'subType', $elm$json$Json$Decode$string));
}();
var $author$project$SharedSync$decodeWall = A2(
	$elm$json$Json$Decode$andThen,
	function (s) {
		var _v0 = $elm$core$String$toLower(s);
		switch (_v0) {
			case 'huge-rock':
				return $elm$json$Json$Decode$succeed(
					$author$project$BoardOverlay$Wall(0));
			case 'iron':
				return $elm$json$Json$Decode$succeed(
					$author$project$BoardOverlay$Wall(1));
			case 'large-rock':
				return $elm$json$Json$Decode$succeed(
					$author$project$BoardOverlay$Wall(2));
			case 'obsidian-glass':
				return $elm$json$Json$Decode$succeed(
					$author$project$BoardOverlay$Wall(3));
			case 'rock':
				return $elm$json$Json$Decode$succeed(
					$author$project$BoardOverlay$Wall(4));
			default:
				return $elm$json$Json$Decode$fail(s + ' is not a wall sub-type');
		}
	},
	A2($elm$json$Json$Decode$field, 'subType', $elm$json$Json$Decode$string));
var $author$project$Colour$Colour = F4(
	function (red, green, blue, alpha) {
		return {aO: alpha, aq: blue, az: green, aH: red};
	});
var $elm$core$String$cons = _String_cons;
var $elm$core$String$fromChar = function (_char) {
	return A2($elm$core$String$cons, _char, '');
};
var $elm$core$Basics$pow = _Basics_pow;
var $rtfeldman$elm_hex$Hex$fromStringHelp = F3(
	function (position, chars, accumulated) {
		fromStringHelp:
		while (true) {
			if (!chars.b) {
				return $elm$core$Result$Ok(accumulated);
			} else {
				var _char = chars.a;
				var rest = chars.b;
				switch (_char) {
					case '0':
						var $temp$position = position - 1,
							$temp$chars = rest,
							$temp$accumulated = accumulated;
						position = $temp$position;
						chars = $temp$chars;
						accumulated = $temp$accumulated;
						continue fromStringHelp;
					case '1':
						var $temp$position = position - 1,
							$temp$chars = rest,
							$temp$accumulated = accumulated + A2($elm$core$Basics$pow, 16, position);
						position = $temp$position;
						chars = $temp$chars;
						accumulated = $temp$accumulated;
						continue fromStringHelp;
					case '2':
						var $temp$position = position - 1,
							$temp$chars = rest,
							$temp$accumulated = accumulated + (2 * A2($elm$core$Basics$pow, 16, position));
						position = $temp$position;
						chars = $temp$chars;
						accumulated = $temp$accumulated;
						continue fromStringHelp;
					case '3':
						var $temp$position = position - 1,
							$temp$chars = rest,
							$temp$accumulated = accumulated + (3 * A2($elm$core$Basics$pow, 16, position));
						position = $temp$position;
						chars = $temp$chars;
						accumulated = $temp$accumulated;
						continue fromStringHelp;
					case '4':
						var $temp$position = position - 1,
							$temp$chars = rest,
							$temp$accumulated = accumulated + (4 * A2($elm$core$Basics$pow, 16, position));
						position = $temp$position;
						chars = $temp$chars;
						accumulated = $temp$accumulated;
						continue fromStringHelp;
					case '5':
						var $temp$position = position - 1,
							$temp$chars = rest,
							$temp$accumulated = accumulated + (5 * A2($elm$core$Basics$pow, 16, position));
						position = $temp$position;
						chars = $temp$chars;
						accumulated = $temp$accumulated;
						continue fromStringHelp;
					case '6':
						var $temp$position = position - 1,
							$temp$chars = rest,
							$temp$accumulated = accumulated + (6 * A2($elm$core$Basics$pow, 16, position));
						position = $temp$position;
						chars = $temp$chars;
						accumulated = $temp$accumulated;
						continue fromStringHelp;
					case '7':
						var $temp$position = position - 1,
							$temp$chars = rest,
							$temp$accumulated = accumulated + (7 * A2($elm$core$Basics$pow, 16, position));
						position = $temp$position;
						chars = $temp$chars;
						accumulated = $temp$accumulated;
						continue fromStringHelp;
					case '8':
						var $temp$position = position - 1,
							$temp$chars = rest,
							$temp$accumulated = accumulated + (8 * A2($elm$core$Basics$pow, 16, position));
						position = $temp$position;
						chars = $temp$chars;
						accumulated = $temp$accumulated;
						continue fromStringHelp;
					case '9':
						var $temp$position = position - 1,
							$temp$chars = rest,
							$temp$accumulated = accumulated + (9 * A2($elm$core$Basics$pow, 16, position));
						position = $temp$position;
						chars = $temp$chars;
						accumulated = $temp$accumulated;
						continue fromStringHelp;
					case 'a':
						var $temp$position = position - 1,
							$temp$chars = rest,
							$temp$accumulated = accumulated + (10 * A2($elm$core$Basics$pow, 16, position));
						position = $temp$position;
						chars = $temp$chars;
						accumulated = $temp$accumulated;
						continue fromStringHelp;
					case 'b':
						var $temp$position = position - 1,
							$temp$chars = rest,
							$temp$accumulated = accumulated + (11 * A2($elm$core$Basics$pow, 16, position));
						position = $temp$position;
						chars = $temp$chars;
						accumulated = $temp$accumulated;
						continue fromStringHelp;
					case 'c':
						var $temp$position = position - 1,
							$temp$chars = rest,
							$temp$accumulated = accumulated + (12 * A2($elm$core$Basics$pow, 16, position));
						position = $temp$position;
						chars = $temp$chars;
						accumulated = $temp$accumulated;
						continue fromStringHelp;
					case 'd':
						var $temp$position = position - 1,
							$temp$chars = rest,
							$temp$accumulated = accumulated + (13 * A2($elm$core$Basics$pow, 16, position));
						position = $temp$position;
						chars = $temp$chars;
						accumulated = $temp$accumulated;
						continue fromStringHelp;
					case 'e':
						var $temp$position = position - 1,
							$temp$chars = rest,
							$temp$accumulated = accumulated + (14 * A2($elm$core$Basics$pow, 16, position));
						position = $temp$position;
						chars = $temp$chars;
						accumulated = $temp$accumulated;
						continue fromStringHelp;
					case 'f':
						var $temp$position = position - 1,
							$temp$chars = rest,
							$temp$accumulated = accumulated + (15 * A2($elm$core$Basics$pow, 16, position));
						position = $temp$position;
						chars = $temp$chars;
						accumulated = $temp$accumulated;
						continue fromStringHelp;
					default:
						var nonHex = _char;
						return $elm$core$Result$Err(
							$elm$core$String$fromChar(nonHex) + ' is not a valid hexadecimal character.');
				}
			}
		}
	});
var $elm$core$Result$map = F2(
	function (func, ra) {
		if (!ra.$) {
			var a = ra.a;
			return $elm$core$Result$Ok(
				func(a));
		} else {
			var e = ra.a;
			return $elm$core$Result$Err(e);
		}
	});
var $elm$core$Result$mapError = F2(
	function (f, result) {
		if (!result.$) {
			var v = result.a;
			return $elm$core$Result$Ok(v);
		} else {
			var e = result.a;
			return $elm$core$Result$Err(
				f(e));
		}
	});
var $elm$core$List$tail = function (list) {
	if (list.b) {
		var x = list.a;
		var xs = list.b;
		return $elm$core$Maybe$Just(xs);
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $elm$core$String$foldr = _String_foldr;
var $elm$core$String$toList = function (string) {
	return A3($elm$core$String$foldr, $elm$core$List$cons, _List_Nil, string);
};
var $rtfeldman$elm_hex$Hex$fromString = function (str) {
	if ($elm$core$String$isEmpty(str)) {
		return $elm$core$Result$Err('Empty strings are not valid hexadecimal strings.');
	} else {
		var result = function () {
			if (A2($elm$core$String$startsWith, '-', str)) {
				var list = A2(
					$elm$core$Maybe$withDefault,
					_List_Nil,
					$elm$core$List$tail(
						$elm$core$String$toList(str)));
				return A2(
					$elm$core$Result$map,
					$elm$core$Basics$negate,
					A3(
						$rtfeldman$elm_hex$Hex$fromStringHelp,
						$elm$core$List$length(list) - 1,
						list,
						0));
			} else {
				return A3(
					$rtfeldman$elm_hex$Hex$fromStringHelp,
					$elm$core$String$length(str) - 1,
					$elm$core$String$toList(str),
					0);
			}
		}();
		var formatError = function (err) {
			return A2(
				$elm$core$String$join,
				' ',
				_List_fromArray(
					['\"' + (str + '\"'), 'is not a valid hexadecimal string because', err]));
		};
		return A2($elm$core$Result$mapError, formatError, result);
	}
};
var $author$project$Colour$hexToInt = function (hex) {
	var _v0 = $rtfeldman$elm_hex$Hex$fromString(hex);
	if (!_v0.$) {
		var i = _v0.a;
		return i;
	} else {
		return 0;
	}
};
var $elm$core$String$replace = F3(
	function (before, after, string) {
		return A2(
			$elm$core$String$join,
			after,
			A2($elm$core$String$split, before, string));
	});
var $author$project$Colour$fromHexString = function (str) {
	var strNoHash = A3($elm$core$String$replace, '#', '', str);
	return A4(
		$author$project$Colour$Colour,
		$author$project$Colour$hexToInt(
			A2($elm$core$String$left, 2, strNoHash)),
		$author$project$Colour$hexToInt(
			A2(
				$elm$core$String$left,
				2,
				A2($elm$core$String$dropLeft, 2, strNoHash))),
		$author$project$Colour$hexToInt(
			A2(
				$elm$core$String$left,
				2,
				A2($elm$core$String$dropLeft, 4, strNoHash))),
		($elm$core$String$length(strNoHash) > 6) ? $author$project$Colour$hexToInt(
			A2(
				$elm$core$String$left,
				2,
				A2($elm$core$String$dropLeft, 6, strNoHash))) : 1);
};
var $author$project$SharedSync$decodeBoardOverlayType = function () {
	var decodeType = function (typeName) {
		var _v0 = $elm$core$String$toLower(typeName);
		switch (_v0) {
			case 'door':
				return A2($elm$json$Json$Decode$andThen, $author$project$SharedSync$decodeDoorRefs, $author$project$SharedSync$decodeDoor);
			case 'difficult-terrain':
				return $author$project$SharedSync$decodeDifficultTerrain;
			case 'hazard':
				return $author$project$SharedSync$decodeHazard;
			case 'highlight':
				return A2(
					$elm$json$Json$Decode$andThen,
					function (c) {
						return $elm$json$Json$Decode$succeed(
							$author$project$BoardOverlay$Highlight(
								$author$project$Colour$fromHexString(c)));
					},
					A2($elm$json$Json$Decode$field, 'colour', $elm$json$Json$Decode$string));
			case 'obstacle':
				return $author$project$SharedSync$decodeObstacle;
			case 'rift':
				return $elm$json$Json$Decode$succeed($author$project$BoardOverlay$Rift);
			case 'starting-location':
				return $elm$json$Json$Decode$succeed($author$project$BoardOverlay$StartingLocation);
			case 'trap':
				return $author$project$SharedSync$decodeTrap;
			case 'treasure':
				return $author$project$SharedSync$decodeTreasure;
			case 'token':
				return $author$project$SharedSync$decodeToken;
			case 'wall':
				return $author$project$SharedSync$decodeWall;
			default:
				return $elm$json$Json$Decode$fail('Unknown overlay type: ' + typeName);
		}
	};
	return A2(
		$elm$json$Json$Decode$andThen,
		decodeType,
		A2($elm$json$Json$Decode$field, 'type', $elm$json$Json$Decode$string));
}();
var $elm$json$Json$Decode$index = _Json_decodeIndex;
var $elm$json$Json$Decode$map4 = _Json_map4;
var $elm$json$Json$Decode$oneOf = _Json_oneOf;
var $elm$json$Json$Decode$maybe = function (decoder) {
	return $elm$json$Json$Decode$oneOf(
		_List_fromArray(
			[
				A2($elm$json$Json$Decode$map, $elm$core$Maybe$Just, decoder),
				$elm$json$Json$Decode$succeed($elm$core$Maybe$Nothing)
			]));
};
var $elm$core$Tuple$pair = F2(
	function (a, b) {
		return _Utils_Tuple2(a, b);
	});
var $author$project$SharedSync$decodeBoardOverlay = A5(
	$elm$json$Json$Decode$map4,
	$author$project$BoardOverlay$BoardOverlay,
	A2($elm$json$Json$Decode$field, 'ref', $author$project$SharedSync$decodeBoardOverlayType),
	A2(
		$elm$json$Json$Decode$andThen,
		function (id) {
			if (!id.$) {
				var i = id.a;
				return $elm$json$Json$Decode$succeed(i);
			} else {
				return $elm$json$Json$Decode$succeed(0);
			}
		},
		$elm$json$Json$Decode$maybe(
			A2($elm$json$Json$Decode$field, 'id', $elm$json$Json$Decode$int))),
	A2(
		$elm$json$Json$Decode$andThen,
		$author$project$SharedSync$decodeBoardOverlayDirection,
		A2($elm$json$Json$Decode$field, 'direction', $elm$json$Json$Decode$string)),
	A2(
		$elm$json$Json$Decode$field,
		'cells',
		$elm$json$Json$Decode$list(
			A3(
				$elm$json$Json$Decode$map2,
				$elm$core$Tuple$pair,
				A2($elm$json$Json$Decode$index, 0, $elm$json$Json$Decode$int),
				A2($elm$json$Json$Decode$index, 1, $elm$json$Json$Decode$int)))));
var $author$project$AppStorage$ExtendedRoomData = F2(
	function (data, rotationPoint) {
		return {a$: data, bU: rotationPoint};
	});
var $author$project$SharedSync$decodeCoords = A2(
	$elm$json$Json$Decode$andThen,
	function (x) {
		return A2(
			$elm$json$Json$Decode$andThen,
			function (y) {
				return $elm$json$Json$Decode$succeed(
					_Utils_Tuple2(x, y));
			},
			A2($elm$json$Json$Decode$field, 'y', $elm$json$Json$Decode$int));
	},
	A2($elm$json$Json$Decode$field, 'x', $elm$json$Json$Decode$int));
var $author$project$Game$RoomData = F3(
	function (ref, origin, turns) {
		return {dj: origin, bJ: ref, dL: turns};
	});
var $elm$json$Json$Decode$map3 = _Json_map3;
var $author$project$GameSync$decodeRoom = A4(
	$elm$json$Json$Decode$map3,
	$author$project$Game$RoomData,
	A2(
		$elm$json$Json$Decode$andThen,
		function (s) {
			var _v0 = $author$project$BoardMapTile$stringToRef(s);
			if (!_v0.$) {
				var r = _v0.a;
				return $elm$json$Json$Decode$succeed(r);
			} else {
				return $elm$json$Json$Decode$fail('Cannot decode room ref ' + s);
			}
		},
		A2($elm$json$Json$Decode$field, 'ref', $elm$json$Json$Decode$string)),
	A2($elm$json$Json$Decode$field, 'origin', $author$project$SharedSync$decodeCoords),
	A2($elm$json$Json$Decode$field, 'turns', $elm$json$Json$Decode$int));
var $author$project$AppStorage$decodeExtendedRoomData = A3(
	$elm$json$Json$Decode$map2,
	$author$project$AppStorage$ExtendedRoomData,
	A2($elm$json$Json$Decode$field, 'data', $author$project$GameSync$decodeRoom),
	A2($elm$json$Json$Decode$field, 'rotationPoint', $author$project$SharedSync$decodeCoords));
var $author$project$Monster$Monster = F5(
	function (monster, id, level, wasSummoned, outOfPhase) {
		return {ag: id, bj: level, m: monster, bz: outOfPhase, cg: wasSummoned};
	});
var $author$project$Monster$None = 0;
var $author$project$Scenario$ScenarioMonster = F6(
	function (monster, initialX, initialY, twoPlayer, threePlayer, fourPlayer) {
		return {cP: fourPlayer, be: initialX, bf: initialY, m: monster, dF: threePlayer, dM: twoPlayer};
	});
var $author$project$Monster$Elite = 2;
var $author$project$Monster$Normal = 1;
var $author$project$SharedSync$decodeMonsterLevel = function (l) {
	var _v0 = $elm$core$String$toLower(l);
	switch (_v0) {
		case 'normal':
			return $elm$json$Json$Decode$succeed(1);
		case 'elite':
			return $elm$json$Json$Decode$succeed(2);
		case 'none':
			return $elm$json$Json$Decode$succeed(0);
		default:
			return $elm$json$Json$Decode$fail(l + ' is not a valid monster level');
	}
};
var $elm$json$Json$Decode$map6 = _Json_map6;
var $author$project$Monster$BossType = function (a) {
	return {$: 1, a: a};
};
var $author$project$Monster$NormalType = function (a) {
	return {$: 0, a: a};
};
var $author$project$Monster$BanditCommander = 0;
var $author$project$Monster$CaptainOfTheGuard = 5;
var $author$project$Monster$DarkRider = 12;
var $author$project$Monster$ElderDrake = 8;
var $author$project$Monster$HumanCommander = 1;
var $author$project$Monster$InoxBodyguard = 4;
var $author$project$Monster$Jekserah = 6;
var $author$project$Monster$ManifestationOfCorruption = 15;
var $author$project$Monster$MercilessOverseer = 3;
var $author$project$Monster$PrimeDemon = 7;
var $author$project$Monster$TheBetrayer = 9;
var $author$project$Monster$TheColorless = 10;
var $author$project$Monster$TheGloom = 14;
var $author$project$Monster$TheSightlessEye = 11;
var $author$project$Monster$ValrathCommander = 2;
var $author$project$Monster$WingedHorror = 13;
var $author$project$Monster$bossDict = $elm$core$Dict$fromList(
	_List_fromArray(
		[
			_Utils_Tuple2('bandit-commander', 0),
			_Utils_Tuple2('human-commander', 1),
			_Utils_Tuple2('valrath-commander', 2),
			_Utils_Tuple2('merciless-overseer', 3),
			_Utils_Tuple2('inox-bodyguard', 4),
			_Utils_Tuple2('captain-of-the-guard', 5),
			_Utils_Tuple2('jekserah', 6),
			_Utils_Tuple2('prime-demon', 7),
			_Utils_Tuple2('elder-drake', 8),
			_Utils_Tuple2('the-betrayer', 9),
			_Utils_Tuple2('the-colorless', 10),
			_Utils_Tuple2('the-sightless-eye', 11),
			_Utils_Tuple2('dark-rider', 12),
			_Utils_Tuple2('winged-horror', 13),
			_Utils_Tuple2('the-gloom', 14),
			_Utils_Tuple2('manifestation-of-corruption', 15)
		]));
var $elm$core$Maybe$map = F2(
	function (f, maybe) {
		if (!maybe.$) {
			var value = maybe.a;
			return $elm$core$Maybe$Just(
				f(value));
		} else {
			return $elm$core$Maybe$Nothing;
		}
	});
var $author$project$Monster$AestherAshblade = 0;
var $author$project$Monster$AestherScout = 1;
var $author$project$Monster$AncientArtillery = 29;
var $author$project$Monster$BanditArcher = 3;
var $author$project$Monster$BanditGuard = 2;
var $author$project$Monster$BlackImp = 37;
var $author$project$Monster$CaveBear = 27;
var $author$project$Monster$CityArcher = 5;
var $author$project$Monster$CityGuard = 4;
var $author$project$Monster$Cultist = 16;
var $author$project$Monster$DeepTerror = 36;
var $author$project$Monster$EarthDemon = 19;
var $author$project$Monster$FlameDemon = 17;
var $author$project$Monster$ForestImp = 25;
var $author$project$Monster$FrostDemon = 18;
var $author$project$Monster$GiantViper = 24;
var $author$project$Monster$HarrowerInfester = 35;
var $author$project$Monster$Hound = 26;
var $author$project$Monster$InoxArcher = 7;
var $author$project$Monster$InoxGuard = 6;
var $author$project$Monster$InoxShaman = 8;
var $author$project$Monster$LivingBones = 13;
var $author$project$Monster$LivingCorpse = 14;
var $author$project$Monster$LivingSpirit = 15;
var $author$project$Monster$Lurker = 32;
var $author$project$Monster$NightDemon = 21;
var $author$project$Monster$Ooze = 23;
var $author$project$Monster$RendingDrake = 30;
var $author$project$Monster$SavvaLavaflow = 34;
var $author$project$Monster$SavvasIcestorm = 33;
var $author$project$Monster$SpittingDrake = 31;
var $author$project$Monster$StoneGolem = 28;
var $author$project$Monster$SunDemon = 22;
var $author$project$Monster$ValrathSavage = 10;
var $author$project$Monster$ValrathTracker = 9;
var $author$project$Monster$VermlingScout = 11;
var $author$project$Monster$VermlingShaman = 12;
var $author$project$Monster$WindDemon = 20;
var $author$project$Monster$normalDict = $elm$core$Dict$fromList(
	_List_fromArray(
		[
			_Utils_Tuple2('aesther-ashblade', 0),
			_Utils_Tuple2('aesther-scout', 1),
			_Utils_Tuple2('bandit-guard', 2),
			_Utils_Tuple2('bandit-archer', 3),
			_Utils_Tuple2('city-guard', 4),
			_Utils_Tuple2('city-archer', 5),
			_Utils_Tuple2('inox-guard', 6),
			_Utils_Tuple2('inox-archer', 7),
			_Utils_Tuple2('inox-shaman', 8),
			_Utils_Tuple2('valrath-tracker', 9),
			_Utils_Tuple2('valrath-savage', 10),
			_Utils_Tuple2('vermling-scout', 11),
			_Utils_Tuple2('vermling-shaman', 12),
			_Utils_Tuple2('living-bones', 13),
			_Utils_Tuple2('living-corpse', 14),
			_Utils_Tuple2('living-spirit', 15),
			_Utils_Tuple2('cultist', 16),
			_Utils_Tuple2('flame-demon', 17),
			_Utils_Tuple2('frost-demon', 18),
			_Utils_Tuple2('earth-demon', 19),
			_Utils_Tuple2('wind-demon', 20),
			_Utils_Tuple2('night-demon', 21),
			_Utils_Tuple2('sun-demon', 22),
			_Utils_Tuple2('ooze', 23),
			_Utils_Tuple2('giant-viper', 24),
			_Utils_Tuple2('forest-imp', 25),
			_Utils_Tuple2('hound', 26),
			_Utils_Tuple2('cave-bear', 27),
			_Utils_Tuple2('stone-golem', 28),
			_Utils_Tuple2('ancient-artillery', 29),
			_Utils_Tuple2('rending-drake', 30),
			_Utils_Tuple2('spitting-drake', 31),
			_Utils_Tuple2('lurker', 32),
			_Utils_Tuple2('savvas-icestorm', 33),
			_Utils_Tuple2('savvas-lavaflow', 34),
			_Utils_Tuple2('harrower-infester', 35),
			_Utils_Tuple2('deep-terror', 36),
			_Utils_Tuple2('black-imp', 37)
		]));
var $author$project$Monster$stringToMonsterType = function (monster) {
	var _v0 = A2(
		$elm$core$Dict$get,
		$elm$core$String$toLower(monster),
		$author$project$Monster$normalDict);
	if (!_v0.$) {
		var m = _v0.a;
		return $elm$core$Maybe$Just(
			$author$project$Monster$NormalType(m));
	} else {
		return A2(
			$elm$core$Maybe$map,
			function (v) {
				return $author$project$Monster$BossType(v);
			},
			A2(
				$elm$core$Dict$get,
				$elm$core$String$toLower(monster),
				$author$project$Monster$bossDict));
	}
};
var $author$project$SharedSync$decodeScenarioMonster = A7(
	$elm$json$Json$Decode$map6,
	$author$project$Scenario$ScenarioMonster,
	A2(
		$elm$json$Json$Decode$andThen,
		function (m) {
			var _v0 = $author$project$Monster$stringToMonsterType(m);
			if (!_v0.$) {
				var monster = _v0.a;
				return $elm$json$Json$Decode$succeed(
					A5($author$project$Monster$Monster, monster, 0, 0, false, false));
			} else {
				return $elm$json$Json$Decode$fail('Could not decode monster ' + m);
			}
		},
		A2($elm$json$Json$Decode$field, 'monster', $elm$json$Json$Decode$string)),
	A2($elm$json$Json$Decode$field, 'initialX', $elm$json$Json$Decode$int),
	A2($elm$json$Json$Decode$field, 'initialY', $elm$json$Json$Decode$int),
	A2(
		$elm$json$Json$Decode$andThen,
		$author$project$SharedSync$decodeMonsterLevel,
		A2($elm$json$Json$Decode$field, 'twoPlayer', $elm$json$Json$Decode$string)),
	A2(
		$elm$json$Json$Decode$andThen,
		$author$project$SharedSync$decodeMonsterLevel,
		A2($elm$json$Json$Decode$field, 'threePlayer', $elm$json$Json$Decode$string)),
	A2(
		$elm$json$Json$Decode$andThen,
		$author$project$SharedSync$decodeMonsterLevel,
		A2($elm$json$Json$Decode$field, 'fourPlayer', $elm$json$Json$Decode$string)));
var $author$project$AppStorage$mapDataDecoder = A5(
	$elm$json$Json$Decode$map4,
	$author$project$AppStorage$MapData,
	A2($elm$json$Json$Decode$field, 'scenarioTitle', $elm$json$Json$Decode$string),
	A2(
		$elm$json$Json$Decode$field,
		'roomData',
		$elm$json$Json$Decode$list($author$project$AppStorage$decodeExtendedRoomData)),
	A2(
		$elm$json$Json$Decode$field,
		'overlays',
		$elm$json$Json$Decode$list($author$project$SharedSync$decodeBoardOverlay)),
	A2(
		$elm$json$Json$Decode$field,
		'monsters',
		$elm$json$Json$Decode$list($author$project$SharedSync$decodeScenarioMonster)));
var $author$project$AppStorage$loadMapFromStorage = function (value) {
	return A2($elm$json$Json$Decode$decodeValue, $author$project$AppStorage$mapDataDecoder, value);
};
var $elm$core$Platform$Cmd$batch = _Platform_batch;
var $elm$core$Platform$Cmd$none = $elm$core$Platform$Cmd$batch(_List_Nil);
var $author$project$Creator$init = function (initMap) {
	var mapData = function () {
		if (!initMap.$) {
			var m = initMap.a;
			var _v1 = $author$project$AppStorage$loadMapFromStorage(m);
			if (!_v1.$) {
				var map = _v1.a;
				return map;
			} else {
				return A4($author$project$AppStorage$MapData, '', _List_Nil, _List_Nil, _List_Nil);
			}
		} else {
			return A4($author$project$AppStorage$MapData, '', _List_Nil, _List_Nil, _List_Nil);
		}
	}();
	return _Utils_Tuple2(
		$author$project$Creator$initModel(mapData),
		$elm$core$Platform$Cmd$none);
};
var $elm$json$Json$Decode$null = _Json_decodeNull;
var $author$project$Creator$CellFromPoint = function (a) {
	return {$: 8, a: a};
};
var $author$project$Creator$ChangeContextMenuAbsposition = function (a) {
	return {$: 14, a: a};
};
var $author$project$Creator$CreateNew = function (a) {
	return {$: 21, a: a};
};
var $elm$core$Platform$Sub$batch = _Platform_batch;
var $elm$json$Json$Decode$bool = _Json_decodeBool;
var $author$project$Creator$onCellFromPoint = _Platform_incomingPort(
	'onCellFromPoint',
	A2(
		$elm$json$Json$Decode$andThen,
		function (_v0) {
			return A2(
				$elm$json$Json$Decode$andThen,
				function (_v1) {
					return A2(
						$elm$json$Json$Decode$andThen,
						function (_v2) {
							return $elm$json$Json$Decode$succeed(
								_Utils_Tuple3(_v0, _v1, _v2));
						},
						A2($elm$json$Json$Decode$index, 2, $elm$json$Json$Decode$bool));
				},
				A2($elm$json$Json$Decode$index, 1, $elm$json$Json$Decode$int));
		},
		A2($elm$json$Json$Decode$index, 0, $elm$json$Json$Decode$int)));
var $author$project$Creator$onConfirmCreateNew = _Platform_incomingPort(
	'onConfirmCreateNew',
	$elm$json$Json$Decode$null(0));
var $author$project$Creator$onContextPosition = _Platform_incomingPort(
	'onContextPosition',
	A2(
		$elm$json$Json$Decode$andThen,
		function (_v0) {
			return A2(
				$elm$json$Json$Decode$andThen,
				function (_v1) {
					return $elm$json$Json$Decode$succeed(
						_Utils_Tuple2(_v0, _v1));
				},
				A2($elm$json$Json$Decode$index, 1, $elm$json$Json$Decode$int));
		},
		A2($elm$json$Json$Decode$index, 0, $elm$json$Json$Decode$int)));
var $author$project$Creator$subscriptions = function (_v0) {
	return $elm$core$Platform$Sub$batch(
		_List_fromArray(
			[
				$author$project$Creator$onContextPosition($author$project$Creator$ChangeContextMenuAbsposition),
				$author$project$Creator$onCellFromPoint($author$project$Creator$CellFromPoint),
				$author$project$Creator$onConfirmCreateNew($author$project$Creator$CreateNew)
			]));
};
var $author$project$Game$AI = function (a) {
	return {$: 2, a: a};
};
var $author$project$Character$Brute = 3;
var $author$project$Character$Cragheart = 4;
var $author$project$Game$CustomScenario = function (a) {
	return {$: 1, a: a};
};
var $author$project$Game$Enemy = function (a) {
	return {$: 0, a: a};
};
var $author$project$Creator$ExtractFileString = function (a) {
	return {$: 24, a: a};
};
var $author$project$Creator$LoadScenario = function (a) {
	return {$: 25, a: a};
};
var $author$project$Creator$MoveCanceled = {$: 2};
var $author$project$Creator$MoveCompleted = {$: 3};
var $author$project$Creator$MoveStarted = F2(
	function (a, b) {
		return {$: 0, a: a, b: b};
	});
var $author$project$Creator$MoveTargetChanged = F2(
	function (a, b) {
		return {$: 1, a: a, b: b};
	});
var $author$project$AppStorage$MoveablePiece = F3(
	function (ref, coords, target) {
		return {aY: coords, bJ: ref, b9: target};
	});
var $author$project$BoardHtml$Open = 0;
var $author$project$Creator$OpenContextMenu = function (a) {
	return {$: 11, a: a};
};
var $author$project$AppStorage$OverlayType = F2(
	function (a, b) {
		return {$: 0, a: a, b: b};
	});
var $author$project$Game$Piece = F3(
	function (ref, x, y) {
		return {bJ: ref, ci: x, cj: y};
	});
var $author$project$AppStorage$PieceType = function (a) {
	return {$: 1, a: a};
};
var $author$project$AppStorage$RoomType = function (a) {
	return {$: 2, a: a};
};
var $author$project$Character$Spellweaver = 15;
var $author$project$Character$Tinkerer = 18;
var $elm$core$Maybe$andThen = F2(
	function (callback, maybeValue) {
		if (!maybeValue.$) {
			var value = maybeValue.a;
			return callback(value);
		} else {
			return $elm$core$Maybe$Nothing;
		}
	});
var $author$project$Scenario$Scenario = F5(
	function (id, title, mapTilesData, angle, additionalMonsters) {
		return {cm: additionalMonsters, cp: angle, ag: id, bl: mapTilesData, dJ: title};
	});
var $author$project$ScenarioSync$DoorDataObj = F7(
	function (subType, dir, room1X, room1Y, room2X, room2Y, mapTilesData) {
		return {a2: dir, bl: mapTilesData, bO: room1X, bP: room1Y, bQ: room2X, bR: room2Y, b5: subType};
	});
var $author$project$Scenario$DoorLink = F5(
	function (a, b, c, d, e) {
		return {$: 0, a: a, b: b, c: c, d: d, e: e};
	});
var $author$project$Scenario$MapTileData = F5(
	function (ref, doors, overlays, monsters, turns) {
		return {cD: doors, bn: monsters, bA: overlays, bJ: ref, dL: turns};
	});
var $elm$json$Json$Decode$lazy = function (thunk) {
	return A2(
		$elm$json$Json$Decode$andThen,
		thunk,
		$elm$json$Json$Decode$succeed(0));
};
var $elm$json$Json$Decode$map5 = _Json_map5;
var $elm$json$Json$Decode$map7 = _Json_map7;
function $author$project$ScenarioSync$cyclic$decodeMapTileData() {
	return A6(
		$elm$json$Json$Decode$map5,
		$author$project$Scenario$MapTileData,
		A2(
			$elm$json$Json$Decode$andThen,
			function (r) {
				var _v1 = $author$project$BoardMapTile$stringToRef(r);
				if (!_v1.$) {
					var ref = _v1.a;
					return $elm$json$Json$Decode$succeed(ref);
				} else {
					return $elm$json$Json$Decode$fail('Could not find tile reference ' + r);
				}
			},
			A2($elm$json$Json$Decode$field, 'ref', $elm$json$Json$Decode$string)),
		A2(
			$elm$json$Json$Decode$field,
			'doors',
			$elm$json$Json$Decode$list(
				$author$project$ScenarioSync$cyclic$decodeDoors())),
		A2(
			$elm$json$Json$Decode$field,
			'overlays',
			$elm$json$Json$Decode$list($author$project$SharedSync$decodeBoardOverlay)),
		A2(
			$elm$json$Json$Decode$field,
			'monsters',
			$elm$json$Json$Decode$list($author$project$SharedSync$decodeScenarioMonster)),
		A2($elm$json$Json$Decode$field, 'turns', $elm$json$Json$Decode$int));
}
function $author$project$ScenarioSync$cyclic$decodeDoors() {
	return A2(
		$elm$json$Json$Decode$andThen,
		function (d) {
			return $elm$json$Json$Decode$succeed(
				A5(
					$author$project$Scenario$DoorLink,
					d.b5,
					d.a2,
					_Utils_Tuple2(d.bO, d.bP),
					_Utils_Tuple2(d.bQ, d.bR),
					d.bl));
		},
		A8(
			$elm$json$Json$Decode$map7,
			$author$project$ScenarioSync$DoorDataObj,
			$author$project$SharedSync$decodeDoor,
			A2(
				$elm$json$Json$Decode$andThen,
				$author$project$SharedSync$decodeBoardOverlayDirection,
				A2($elm$json$Json$Decode$field, 'direction', $elm$json$Json$Decode$string)),
			A2($elm$json$Json$Decode$field, 'room1X', $elm$json$Json$Decode$int),
			A2($elm$json$Json$Decode$field, 'room1Y', $elm$json$Json$Decode$int),
			A2($elm$json$Json$Decode$field, 'room2X', $elm$json$Json$Decode$int),
			A2($elm$json$Json$Decode$field, 'room2Y', $elm$json$Json$Decode$int),
			A2(
				$elm$json$Json$Decode$field,
				'mapTileData',
				$elm$json$Json$Decode$lazy(
					function (_v0) {
						return $author$project$ScenarioSync$cyclic$decodeMapTileData();
					}))));
}
var $author$project$ScenarioSync$decodeMapTileData = $author$project$ScenarioSync$cyclic$decodeMapTileData();
$author$project$ScenarioSync$cyclic$decodeMapTileData = function () {
	return $author$project$ScenarioSync$decodeMapTileData;
};
var $author$project$ScenarioSync$decodeDoors = $author$project$ScenarioSync$cyclic$decodeDoors();
$author$project$ScenarioSync$cyclic$decodeDoors = function () {
	return $author$project$ScenarioSync$decodeDoors;
};
var $elm$core$List$maybeCons = F3(
	function (f, mx, xs) {
		var _v0 = f(mx);
		if (!_v0.$) {
			var x = _v0.a;
			return A2($elm$core$List$cons, x, xs);
		} else {
			return xs;
		}
	});
var $elm$core$List$filterMap = F2(
	function (f, xs) {
		return A3(
			$elm$core$List$foldr,
			$elm$core$List$maybeCons(f),
			_List_Nil,
			xs);
	});
var $author$project$ScenarioSync$decodeMonsterList = function (monsters) {
	var decodedRefs = A2(
		$elm$core$List$map,
		function (ref) {
			return $author$project$Monster$stringToMonsterType(ref);
		},
		monsters);
	return A2(
		$elm$core$List$all,
		function (s) {
			return !_Utils_eq(s, $elm$core$Maybe$Nothing);
		},
		decodedRefs) ? $elm$json$Json$Decode$succeed(
		A2(
			$elm$core$List$filterMap,
			function (m) {
				return m;
			},
			decodedRefs)) : $elm$json$Json$Decode$fail('Could not decode all monster references');
};
var $elm$json$Json$Decode$float = _Json_decodeFloat;
var $author$project$ScenarioSync$decodeScenario = A6(
	$elm$json$Json$Decode$map5,
	$author$project$Scenario$Scenario,
	A2($elm$json$Json$Decode$field, 'id', $elm$json$Json$Decode$int),
	A2($elm$json$Json$Decode$field, 'title', $elm$json$Json$Decode$string),
	A2($elm$json$Json$Decode$field, 'mapTileData', $author$project$ScenarioSync$decodeMapTileData),
	A2($elm$json$Json$Decode$field, 'angle', $elm$json$Json$Decode$float),
	A2(
		$elm$json$Json$Decode$andThen,
		$author$project$ScenarioSync$decodeMonsterList,
		A2(
			$elm$json$Json$Decode$field,
			'additionalMonsters',
			$elm$json$Json$Decode$list($elm$json$Json$Decode$string))));
var $elm$json$Json$Decode$decodeString = _Json_runOnString;
var $elm$core$Array$length = function (_v0) {
	var len = _v0.a;
	return len;
};
var $elm$core$Elm$JsArray$map = _JsArray_map;
var $elm$core$Array$map = F2(
	function (func, _v0) {
		var len = _v0.a;
		var startShift = _v0.b;
		var tree = _v0.c;
		var tail = _v0.d;
		var helper = function (node) {
			if (!node.$) {
				var subTree = node.a;
				return $elm$core$Array$SubTree(
					A2($elm$core$Elm$JsArray$map, helper, subTree));
			} else {
				var values = node.a;
				return $elm$core$Array$Leaf(
					A2($elm$core$Elm$JsArray$map, func, values));
			}
		};
		return A4(
			$elm$core$Array$Array_elm_builtin,
			len,
			startShift,
			A2($elm$core$Elm$JsArray$map, helper, tree),
			A2($elm$core$Elm$JsArray$map, func, tail));
	});
var $author$project$Creator$defaultExtendedRoomData = function (ref) {
	var rotationPoint = function (_v0) {
		var y = _v0.a;
		var x = _v0.b;
		return _Utils_Tuple2((x / 2) | 0, (y / 2) | 0);
	}(
		function (arr) {
			return _Utils_Tuple2(
				$elm$core$Array$length(arr),
				A3(
					$elm$core$Array$foldr,
					F2(
						function (a, b) {
							return A2($elm$core$Basics$max, a, b);
						}),
					0,
					arr));
		}(
			A2(
				$elm$core$Array$map,
				function (row) {
					return $elm$core$Array$length(row);
				},
				$author$project$BoardMapTile$getGridByRef(ref))));
	return {
		a$: A3(
			$author$project$Game$RoomData,
			ref,
			_Utils_Tuple2(0, 0),
			0),
		bU: rotationPoint
	};
};
var $elm$json$Json$Encode$object = function (pairs) {
	return _Json_wrap(
		A3(
			$elm$core$List$foldl,
			F2(
				function (_v0, obj) {
					var k = _v0.a;
					var v = _v0.b;
					return A3(_Json_addField, k, v, obj);
				}),
			_Json_emptyObject(0),
			pairs));
};
var $elm$json$Json$Encode$string = _Json_wrap;
var $author$project$DragPorts$dragover = _Platform_outgoingPort(
	'dragover',
	function ($) {
		return $elm$json$Json$Encode$object(
			_List_fromArray(
				[
					_Utils_Tuple2(
					'dropEffect',
					$elm$json$Json$Encode$string($.cF)),
					_Utils_Tuple2(
					'event',
					$elm$core$Basics$identity($.a6))
				]));
	});
var $author$project$DragPorts$dragstart = _Platform_outgoingPort(
	'dragstart',
	function ($) {
		return $elm$json$Json$Encode$object(
			_List_fromArray(
				[
					_Utils_Tuple2(
					'effectAllowed',
					$elm$json$Json$Encode$string($.cG)),
					_Utils_Tuple2(
					'event',
					$elm$core$Basics$identity($.a6))
				]));
	});
var $elm$core$List$head = function (list) {
	if (list.b) {
		var x = list.a;
		var xs = list.b;
		return $elm$core$Maybe$Just(x);
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $author$project$Monster$monsterTypeToString = function (monster) {
	if (!monster.$) {
		var m = monster.a;
		var maybeKey = $elm$core$List$head(
			$elm$core$Dict$toList(
				A2(
					$elm$core$Dict$filter,
					F2(
						function (_v2, v) {
							return _Utils_eq(v, m);
						}),
					$author$project$Monster$normalDict)));
		return A2(
			$elm$core$Maybe$map,
			function (_v1) {
				var k = _v1.a;
				return k;
			},
			maybeKey);
	} else {
		var b = monster.a;
		var maybeKey = $elm$core$List$head(
			$elm$core$Dict$toList(
				A2(
					$elm$core$Dict$filter,
					F2(
						function (_v4, v) {
							return _Utils_eq(v, b);
						}),
					$author$project$Monster$bossDict)));
		return A2(
			$elm$core$Maybe$map,
			function (_v3) {
				var k = _v3.a;
				return k;
			},
			maybeKey);
	}
};
var $author$project$ScenarioSync$encodeAdditionalMonsters = function (monsters) {
	return A2(
		$elm$core$List$filterMap,
		function (m) {
			return $author$project$Monster$monsterTypeToString(m);
		},
		monsters);
};
var $elm$json$Json$Encode$int = _Json_wrap;
var $author$project$ScenarioSync$encodeDoor = function (doorType) {
	switch (doorType.$) {
		case 2:
			var material = doorType.a;
			var size = doorType.b;
			return _List_fromArray(
				[
					_Utils_Tuple2(
					'subType',
					$elm$json$Json$Encode$string('corridor')),
					_Utils_Tuple2(
					'material',
					$elm$json$Json$Encode$string(
						function () {
							switch (material) {
								case 0:
									return 'dark';
								case 1:
									return 'earth';
								case 2:
									return 'manmade-stone';
								case 3:
									return 'natural-stone';
								case 4:
									return 'pressure-plate';
								default:
									return 'wood';
							}
						}())),
					_Utils_Tuple2(
					'size',
					$elm$json$Json$Encode$int(
						function () {
							if (!size) {
								return 1;
							} else {
								return 2;
							}
						}()))
				]);
		case 0:
			return _List_fromArray(
				[
					_Utils_Tuple2(
					'subType',
					$elm$json$Json$Encode$string('altar'))
				]);
		case 1:
			return _List_fromArray(
				[
					_Utils_Tuple2(
					'subType',
					$elm$json$Json$Encode$string('breakable-wall'))
				]);
		case 3:
			return _List_fromArray(
				[
					_Utils_Tuple2(
					'subType',
					$elm$json$Json$Encode$string('dark-fog'))
				]);
		case 4:
			return _List_fromArray(
				[
					_Utils_Tuple2(
					'subType',
					$elm$json$Json$Encode$string('light-fog'))
				]);
		case 5:
			return _List_fromArray(
				[
					_Utils_Tuple2(
					'subType',
					$elm$json$Json$Encode$string('stone'))
				]);
		default:
			return _List_fromArray(
				[
					_Utils_Tuple2(
					'subType',
					$elm$json$Json$Encode$string('wooden'))
				]);
	}
};
var $author$project$SharedSync$encodeMonsterLevel = function (monsterLevel) {
	switch (monsterLevel) {
		case 0:
			return 'none';
		case 1:
			return 'normal';
		default:
			return 'elite';
	}
};
var $author$project$SharedSync$encodeMonsters = function (monsters) {
	return A2(
		$elm$core$List$filterMap,
		function (m) {
			return A2(
				$elm$core$Maybe$map,
				function (t) {
					return _List_fromArray(
						[
							_Utils_Tuple2(
							'monster',
							$elm$json$Json$Encode$string(t)),
							_Utils_Tuple2(
							'initialX',
							$elm$json$Json$Encode$int(m.be)),
							_Utils_Tuple2(
							'initialY',
							$elm$json$Json$Encode$int(m.bf)),
							_Utils_Tuple2(
							'twoPlayer',
							$elm$json$Json$Encode$string(
								$author$project$SharedSync$encodeMonsterLevel(m.dM))),
							_Utils_Tuple2(
							'threePlayer',
							$elm$json$Json$Encode$string(
								$author$project$SharedSync$encodeMonsterLevel(m.dF))),
							_Utils_Tuple2(
							'fourPlayer',
							$elm$json$Json$Encode$string(
								$author$project$SharedSync$encodeMonsterLevel(m.cP)))
						]);
				},
				$author$project$Monster$monsterTypeToString(m.m.m));
		},
		monsters);
};
var $author$project$SharedSync$encodeOverlayDirection = function (dir) {
	switch (dir) {
		case 0:
			return 'default';
		case 4:
			return 'diagonal-left';
		case 5:
			return 'diagonal-right';
		case 6:
			return 'diagonal-left-reverse';
		case 7:
			return 'diagonal-right-reverse';
		case 1:
			return 'horizontal';
		case 2:
			return 'vertical';
		default:
			return 'vertical-reverse';
	}
};
var $author$project$SharedSync$encodeOverlayCells = function (cells) {
	return A2(
		$elm$core$List$map,
		function (_v0) {
			var a = _v0.a;
			var b = _v0.b;
			return _List_fromArray(
				[a, b]);
		},
		cells);
};
var $author$project$SharedSync$encodeDifficultTerrain = function (terrain) {
	switch (terrain) {
		case 0:
			return 'log';
		case 1:
			return 'rubble';
		case 2:
			return 'stairs';
		case 3:
			return 'stairs-vert';
		default:
			return 'water';
	}
};
var $author$project$SharedSync$encodeDoor = function (door) {
	switch (door.$) {
		case 0:
			return 'altar';
		case 5:
			return 'stone';
		case 6:
			return 'wooden';
		case 1:
			return 'breakable-wall';
		case 2:
			return 'corridor';
		case 3:
			return 'dark-fog';
		default:
			return 'light-fog';
	}
};
var $author$project$SharedSync$encodeHazard = function (hazard) {
	if (!hazard) {
		return 'hot-coals';
	} else {
		return 'thorns';
	}
};
var $elm$core$List$filter = F2(
	function (isGood, list) {
		return A3(
			$elm$core$List$foldr,
			F2(
				function (x, xs) {
					return isGood(x) ? A2($elm$core$List$cons, x, xs) : xs;
				}),
			_List_Nil,
			list);
	});
var $author$project$BoardMapTile$refToString = function (ref) {
	var maybeKey = $elm$core$List$head(
		$elm$core$Dict$toList(
			A2(
				$elm$core$Dict$filter,
				F2(
					function (_v1, v) {
						return _Utils_eq(v, ref);
					}),
				$author$project$BoardMapTile$boardRefDict)));
	return A2(
		$elm$core$Maybe$map,
		function (_v0) {
			var k = _v0.a;
			return k;
		},
		maybeKey);
};
var $author$project$SharedSync$encodeMapTileRefList = function (refs) {
	return A2(
		$elm$core$List$map,
		function (r) {
			return A2($elm$core$Maybe$withDefault, '', r);
		},
		A2(
			$elm$core$List$filter,
			function (r) {
				return !_Utils_eq(r, $elm$core$Maybe$Nothing);
			},
			A2(
				$elm$core$List$map,
				function (r) {
					return $author$project$BoardMapTile$refToString(r);
				},
				refs)));
};
var $author$project$SharedSync$encodeMaterial = function (m) {
	switch (m) {
		case 0:
			return 'dark';
		case 1:
			return 'earth';
		case 2:
			return 'manmade-stone';
		case 3:
			return 'natural-stone';
		case 4:
			return 'pressure-plate';
		default:
			return 'wood';
	}
};
var $author$project$SharedSync$encodeObstacle = function (obstacle) {
	switch (obstacle) {
		case 0:
			return 'altar';
		case 1:
			return 'barrel';
		case 2:
			return 'bookcase';
		case 3:
			return 'boulder-1';
		case 4:
			return 'boulder-2';
		case 5:
			return 'boulder-3';
		case 6:
			return 'bush';
		case 7:
			return 'cabinet';
		case 8:
			return 'crate';
		case 9:
			return 'crystal';
		case 10:
			return 'dark-pit';
		case 11:
			return 'fountain';
		case 12:
			return 'mirror';
		case 13:
			return 'nest';
		case 14:
			return 'pillar';
		case 15:
			return 'rock-column';
		case 16:
			return 'sarcophagus';
		case 17:
			return 'shelf';
		case 18:
			return 'stalagmites';
		case 19:
			return 'stump';
		case 20:
			return 'table';
		case 21:
			return 'totem';
		case 22:
			return 'tree-3';
		default:
			return 'wall-section';
	}
};
var $author$project$SharedSync$encodeSize = function (i) {
	if (!i) {
		return 1;
	} else {
		return 2;
	}
};
var $author$project$SharedSync$encodeTrap = function (trap) {
	switch (trap) {
		case 0:
			return 'bear';
		case 2:
			return 'spike';
		default:
			return 'poison';
	}
};
var $author$project$SharedSync$encodeTreasureChest = function (chest) {
	switch (chest.$) {
		case 0:
			var i = chest.a;
			return $elm$core$String$fromInt(i);
		case 1:
			return 'goal';
		default:
			return 'locked';
	}
};
var $author$project$SharedSync$encodeTreasure = function (treasure) {
	if (!treasure.$) {
		var c = treasure.a;
		return _List_fromArray(
			[
				_Utils_Tuple2(
				'subType',
				$elm$json$Json$Encode$string('chest')),
				_Utils_Tuple2(
				'id',
				$elm$json$Json$Encode$string(
					$author$project$SharedSync$encodeTreasureChest(c)))
			]);
	} else {
		var i = treasure.a;
		return _List_fromArray(
			[
				_Utils_Tuple2(
				'subType',
				$elm$json$Json$Encode$string('coin')),
				_Utils_Tuple2(
				'amount',
				$elm$json$Json$Encode$int(i))
			]);
	}
};
var $author$project$SharedSync$encodeWall = function (wallType) {
	switch (wallType) {
		case 0:
			return 'huge-rock';
		case 1:
			return 'iron';
		case 2:
			return 'large-rock';
		case 3:
			return 'obsidian-glass';
		default:
			return 'rock';
	}
};
var $elm$json$Json$Encode$list = F2(
	function (func, entries) {
		return _Json_wrap(
			A3(
				$elm$core$List$foldl,
				_Json_addEntry(func),
				_Json_emptyArray(0),
				entries));
	});
var $elm$core$Bitwise$shiftRightBy = _Bitwise_shiftRightBy;
var $elm$core$String$repeatHelp = F3(
	function (n, chunk, result) {
		return (n <= 0) ? result : A3(
			$elm$core$String$repeatHelp,
			n >> 1,
			_Utils_ap(chunk, chunk),
			(!(n & 1)) ? result : _Utils_ap(result, chunk));
	});
var $elm$core$String$repeat = F2(
	function (n, chunk) {
		return A3($elm$core$String$repeatHelp, n, chunk, '');
	});
var $elm$core$String$padLeft = F3(
	function (n, _char, string) {
		return _Utils_ap(
			A2(
				$elm$core$String$repeat,
				n - $elm$core$String$length(string),
				$elm$core$String$fromChar(_char)),
			string);
	});
var $elm$core$String$fromList = _String_fromList;
var $rtfeldman$elm_hex$Hex$unsafeToDigit = function (num) {
	unsafeToDigit:
	while (true) {
		switch (num) {
			case 0:
				return '0';
			case 1:
				return '1';
			case 2:
				return '2';
			case 3:
				return '3';
			case 4:
				return '4';
			case 5:
				return '5';
			case 6:
				return '6';
			case 7:
				return '7';
			case 8:
				return '8';
			case 9:
				return '9';
			case 10:
				return 'a';
			case 11:
				return 'b';
			case 12:
				return 'c';
			case 13:
				return 'd';
			case 14:
				return 'e';
			case 15:
				return 'f';
			default:
				var $temp$num = num;
				num = $temp$num;
				continue unsafeToDigit;
		}
	}
};
var $rtfeldman$elm_hex$Hex$unsafePositiveToDigits = F2(
	function (digits, num) {
		unsafePositiveToDigits:
		while (true) {
			if (num < 16) {
				return A2(
					$elm$core$List$cons,
					$rtfeldman$elm_hex$Hex$unsafeToDigit(num),
					digits);
			} else {
				var $temp$digits = A2(
					$elm$core$List$cons,
					$rtfeldman$elm_hex$Hex$unsafeToDigit(
						A2($elm$core$Basics$modBy, 16, num)),
					digits),
					$temp$num = (num / 16) | 0;
				digits = $temp$digits;
				num = $temp$num;
				continue unsafePositiveToDigits;
			}
		}
	});
var $rtfeldman$elm_hex$Hex$toString = function (num) {
	return $elm$core$String$fromList(
		(num < 0) ? A2(
			$elm$core$List$cons,
			'-',
			A2($rtfeldman$elm_hex$Hex$unsafePositiveToDigits, _List_Nil, -num)) : A2($rtfeldman$elm_hex$Hex$unsafePositiveToDigits, _List_Nil, num));
};
var $author$project$Colour$toHexString = function (colour) {
	return '#' + (A3(
		$elm$core$String$padLeft,
		2,
		'0',
		$rtfeldman$elm_hex$Hex$toString(colour.aH)) + (A3(
		$elm$core$String$padLeft,
		2,
		'0',
		$rtfeldman$elm_hex$Hex$toString(colour.az)) + A3(
		$elm$core$String$padLeft,
		2,
		'0',
		$rtfeldman$elm_hex$Hex$toString(colour.aq))));
};
var $author$project$SharedSync$encodeOverlayType = function (overlay) {
	switch (overlay.$) {
		case 0:
			var d = overlay.a;
			return $elm$json$Json$Encode$object(
				_List_fromArray(
					[
						_Utils_Tuple2(
						'type',
						$elm$json$Json$Encode$string('difficult-terrain')),
						_Utils_Tuple2(
						'subType',
						$elm$json$Json$Encode$string(
							$author$project$SharedSync$encodeDifficultTerrain(d)))
					]));
		case 1:
			if (overlay.a.$ === 2) {
				var _v1 = overlay.a;
				var m = _v1.a;
				var i = _v1.b;
				var refs = overlay.b;
				return $elm$json$Json$Encode$object(
					_List_fromArray(
						[
							_Utils_Tuple2(
							'type',
							$elm$json$Json$Encode$string('door')),
							_Utils_Tuple2(
							'subType',
							$elm$json$Json$Encode$string('corridor')),
							_Utils_Tuple2(
							'material',
							$elm$json$Json$Encode$string(
								$author$project$SharedSync$encodeMaterial(m))),
							_Utils_Tuple2(
							'size',
							$elm$json$Json$Encode$int(
								$author$project$SharedSync$encodeSize(i))),
							_Utils_Tuple2(
							'links',
							A2(
								$elm$json$Json$Encode$list,
								$elm$json$Json$Encode$string,
								$author$project$SharedSync$encodeMapTileRefList(refs)))
						]));
			} else {
				var s = overlay.a;
				var refs = overlay.b;
				return $elm$json$Json$Encode$object(
					_List_fromArray(
						[
							_Utils_Tuple2(
							'type',
							$elm$json$Json$Encode$string('door')),
							_Utils_Tuple2(
							'subType',
							$elm$json$Json$Encode$string(
								$author$project$SharedSync$encodeDoor(s))),
							_Utils_Tuple2(
							'links',
							A2(
								$elm$json$Json$Encode$list,
								$elm$json$Json$Encode$string,
								$author$project$SharedSync$encodeMapTileRefList(refs)))
						]));
			}
		case 2:
			var h = overlay.a;
			return $elm$json$Json$Encode$object(
				_List_fromArray(
					[
						_Utils_Tuple2(
						'type',
						$elm$json$Json$Encode$string('hazard')),
						_Utils_Tuple2(
						'subType',
						$elm$json$Json$Encode$string(
							$author$project$SharedSync$encodeHazard(h)))
					]));
		case 3:
			var c = overlay.a;
			return $elm$json$Json$Encode$object(
				_List_fromArray(
					[
						_Utils_Tuple2(
						'type',
						$elm$json$Json$Encode$string('highlight')),
						_Utils_Tuple2(
						'colour',
						$elm$json$Json$Encode$string(
							$author$project$Colour$toHexString(c)))
					]));
		case 4:
			var o = overlay.a;
			return $elm$json$Json$Encode$object(
				_List_fromArray(
					[
						_Utils_Tuple2(
						'type',
						$elm$json$Json$Encode$string('obstacle')),
						_Utils_Tuple2(
						'subType',
						$elm$json$Json$Encode$string(
							$author$project$SharedSync$encodeObstacle(o)))
					]));
		case 5:
			return $elm$json$Json$Encode$object(
				_List_fromArray(
					[
						_Utils_Tuple2(
						'type',
						$elm$json$Json$Encode$string('rift'))
					]));
		case 6:
			return $elm$json$Json$Encode$object(
				_List_fromArray(
					[
						_Utils_Tuple2(
						'type',
						$elm$json$Json$Encode$string('starting-location'))
					]));
		case 7:
			var t = overlay.a;
			return $elm$json$Json$Encode$object(
				_List_fromArray(
					[
						_Utils_Tuple2(
						'type',
						$elm$json$Json$Encode$string('trap')),
						_Utils_Tuple2(
						'subType',
						$elm$json$Json$Encode$string(
							$author$project$SharedSync$encodeTrap(t)))
					]));
		case 8:
			var t = overlay.a;
			return $elm$json$Json$Encode$object(
				A2(
					$elm$core$List$cons,
					_Utils_Tuple2(
						'type',
						$elm$json$Json$Encode$string('treasure')),
					$author$project$SharedSync$encodeTreasure(t)));
		case 9:
			var t = overlay.a;
			return $elm$json$Json$Encode$object(
				_List_fromArray(
					[
						_Utils_Tuple2(
						'type',
						$elm$json$Json$Encode$string('token')),
						_Utils_Tuple2(
						'value',
						$elm$json$Json$Encode$string(t))
					]));
		default:
			var w = overlay.a;
			return $elm$json$Json$Encode$object(
				_List_fromArray(
					[
						_Utils_Tuple2(
						'type',
						$elm$json$Json$Encode$string('wall')),
						_Utils_Tuple2(
						'subType',
						$elm$json$Json$Encode$string(
							$author$project$SharedSync$encodeWall(w)))
					]));
	}
};
var $author$project$SharedSync$encodeOverlay = function (o) {
	return _List_fromArray(
		[
			_Utils_Tuple2(
			'ref',
			$author$project$SharedSync$encodeOverlayType(o.bJ)),
			_Utils_Tuple2(
			'id',
			$elm$json$Json$Encode$int(o.ag)),
			_Utils_Tuple2(
			'direction',
			$elm$json$Json$Encode$string(
				$author$project$SharedSync$encodeOverlayDirection(o.aw))),
			_Utils_Tuple2(
			'cells',
			A2(
				$elm$json$Json$Encode$list,
				$elm$json$Json$Encode$list($elm$json$Json$Encode$int),
				$author$project$SharedSync$encodeOverlayCells(o.S)))
		]);
};
var $author$project$SharedSync$encodeOverlays = function (overlays) {
	return A2($elm$core$List$map, $author$project$SharedSync$encodeOverlay, overlays);
};
var $elm$json$Json$Encode$null = _Json_encodeNull;
var $author$project$ScenarioSync$encodeDoors = function (doors) {
	return A2(
		$elm$core$List$map,
		function (d) {
			var subType = d.a;
			var direction = d.b;
			var _v2 = d.c;
			var room1X = _v2.a;
			var room1Y = _v2.b;
			var _v3 = d.d;
			var room2X = _v3.a;
			var room2Y = _v3.b;
			var mapTileData = d.e;
			return _Utils_ap(
				$author$project$ScenarioSync$encodeDoor(subType),
				_List_fromArray(
					[
						_Utils_Tuple2(
						'direction',
						$elm$json$Json$Encode$string(
							$author$project$SharedSync$encodeOverlayDirection(direction))),
						_Utils_Tuple2(
						'room1X',
						$elm$json$Json$Encode$int(room1X)),
						_Utils_Tuple2(
						'room1Y',
						$elm$json$Json$Encode$int(room1Y)),
						_Utils_Tuple2(
						'room2X',
						$elm$json$Json$Encode$int(room2X)),
						_Utils_Tuple2(
						'room2Y',
						$elm$json$Json$Encode$int(room2Y)),
						_Utils_Tuple2(
						'mapTileData',
						$elm$json$Json$Encode$object(
							$author$project$ScenarioSync$encodeMapTileData(mapTileData)))
					]));
		},
		doors);
};
var $author$project$ScenarioSync$encodeMapTileData = function (mapTileData) {
	return _List_fromArray(
		[
			_Utils_Tuple2(
			'ref',
			function () {
				var _v0 = $author$project$BoardMapTile$refToString(mapTileData.bJ);
				if (!_v0.$) {
					var s = _v0.a;
					return $elm$json$Json$Encode$string(s);
				} else {
					return $elm$json$Json$Encode$null;
				}
			}()),
			_Utils_Tuple2(
			'doors',
			A2(
				$elm$json$Json$Encode$list,
				$elm$json$Json$Encode$object,
				$author$project$ScenarioSync$encodeDoors(mapTileData.cD))),
			_Utils_Tuple2(
			'overlays',
			A2(
				$elm$json$Json$Encode$list,
				$elm$json$Json$Encode$object,
				$author$project$SharedSync$encodeOverlays(mapTileData.bA))),
			_Utils_Tuple2(
			'monsters',
			A2(
				$elm$json$Json$Encode$list,
				$elm$json$Json$Encode$object,
				$author$project$SharedSync$encodeMonsters(mapTileData.bn))),
			_Utils_Tuple2(
			'turns',
			$elm$json$Json$Encode$int(mapTileData.dL))
		]);
};
var $elm$json$Json$Encode$float = _Json_wrap;
var $author$project$ScenarioSync$encodeScenario = function (scenario) {
	return $elm$json$Json$Encode$object(
		_List_fromArray(
			[
				_Utils_Tuple2(
				'id',
				$elm$json$Json$Encode$int(scenario.ag)),
				_Utils_Tuple2(
				'title',
				$elm$json$Json$Encode$string(scenario.dJ)),
				_Utils_Tuple2(
				'mapTileData',
				$elm$json$Json$Encode$object(
					$author$project$ScenarioSync$encodeMapTileData(scenario.bl))),
				_Utils_Tuple2(
				'angle',
				$elm$json$Json$Encode$float(scenario.cp)),
				_Utils_Tuple2(
				'additionalMonsters',
				A2(
					$elm$json$Json$Encode$list,
					$elm$json$Json$Encode$string,
					$author$project$ScenarioSync$encodeAdditionalMonsters(scenario.cm)))
			]));
};
var $elm$time$Time$Posix = $elm$core$Basics$identity;
var $elm$time$Time$millisToPosix = $elm$core$Basics$identity;
var $elm$file$File$Select$file = F2(
	function (mimes, toMsg) {
		return A2(
			$elm$core$Task$perform,
			toMsg,
			_File_uploadOne(mimes));
	});
var $author$project$Game$Cell = F2(
	function (rooms, passable) {
		return {aG: passable, O: rooms};
	});
var $author$project$Game$Game = F5(
	function (state, scenario, seed, roomData, staticBoard) {
		return {bT: roomData, bX: scenario, b$: seed, ap: state, x: staticBoard};
	});
var $author$project$Game$GameState = F8(
	function (scenario, players, updateCount, visibleRooms, overlays, pieces, availableMonsters, roomCode) {
		return {t: availableMonsters, bA: overlays, bD: pieces, an: players, bS: roomCode, bX: scenario, dO: updateCount, ab: visibleRooms};
	});
var $elm$core$Basics$abs = function (n) {
	return (n < 0) ? (-n) : n;
};
var $elm$core$Basics$always = F2(
	function (a, _v0) {
		return a;
	});
var $author$project$Game$cellsToString = function (cells) {
	return A3(
		$elm$core$List$foldl,
		F2(
			function (s, b) {
				return s + ('|' + b);
			}),
		'',
		A2(
			$elm$core$List$map,
			function (_v0) {
				var x = _v0.a;
				var y = _v0.b;
				return $elm$core$String$fromInt(x) + ('x' + $elm$core$String$fromInt(y));
			},
			cells));
};
var $author$project$BoardOverlay$getBoardOverlayName = function (overlay) {
	var compare = function () {
		switch (overlay.$) {
			case 1:
				var d = overlay.a;
				return A2($author$project$BoardOverlay$Door, d, _List_Nil);
			case 8:
				var t = overlay.a;
				if (!t.$) {
					return $author$project$BoardOverlay$Treasure(
						$author$project$BoardOverlay$Chest($author$project$BoardOverlay$Locked));
				} else {
					return $author$project$BoardOverlay$Treasure(
						$author$project$BoardOverlay$Coin(0));
				}
			default:
				return overlay;
		}
	}();
	return $elm$core$List$head(
		$elm$core$Dict$keys(
			A2(
				$elm$core$Dict$filter,
				F2(
					function (_v0, v) {
						return _Utils_eq(v, compare);
					}),
				$author$project$BoardOverlay$overlayDictionary)));
};
var $elm$core$List$member = F2(
	function (x, xs) {
		return A2(
			$elm$core$List$any,
			function (a) {
				return _Utils_eq(a, x);
			},
			xs);
	});
var $elm_community$list_extra$List$Extra$uniqueHelp = F4(
	function (f, existing, remaining, accumulator) {
		uniqueHelp:
		while (true) {
			if (!remaining.b) {
				return $elm$core$List$reverse(accumulator);
			} else {
				var first = remaining.a;
				var rest = remaining.b;
				var computedFirst = f(first);
				if (A2($elm$core$List$member, computedFirst, existing)) {
					var $temp$f = f,
						$temp$existing = existing,
						$temp$remaining = rest,
						$temp$accumulator = accumulator;
					f = $temp$f;
					existing = $temp$existing;
					remaining = $temp$remaining;
					accumulator = $temp$accumulator;
					continue uniqueHelp;
				} else {
					var $temp$f = f,
						$temp$existing = A2($elm$core$List$cons, computedFirst, existing),
						$temp$remaining = rest,
						$temp$accumulator = A2($elm$core$List$cons, first, accumulator);
					f = $temp$f;
					existing = $temp$existing;
					remaining = $temp$remaining;
					accumulator = $temp$accumulator;
					continue uniqueHelp;
				}
			}
		}
	});
var $elm_community$list_extra$List$Extra$uniqueBy = F2(
	function (f, list) {
		return A4($elm_community$list_extra$List$Extra$uniqueHelp, f, _List_Nil, list, _List_Nil);
	});
var $author$project$Game$ensureUniqueOverlays = function (game) {
	var state = game.ap;
	var pieces = A2(
		$elm_community$list_extra$List$Extra$uniqueBy,
		function (p) {
			return $elm$core$String$fromInt(p.ci) + ('x' + $elm$core$String$fromInt(p.cj));
		},
		state.bD);
	var overlays = A2(
		$elm_community$list_extra$List$Extra$uniqueBy,
		function (o) {
			return _Utils_ap(
				$author$project$Game$cellsToString(o.S),
				A2(
					$elm$core$Maybe$withDefault,
					'',
					$author$project$BoardOverlay$getBoardOverlayName(o.bJ)));
		},
		state.bA);
	return _Utils_update(
		game,
		{
			ap: _Utils_update(
				state,
				{bA: overlays, bD: pieces})
		});
};
var $author$project$Monster$getMonsterBucketSize = function (monster) {
	if (monster.$ === 1) {
		var b = monster.a;
		if (b === 4) {
			return 2;
		} else {
			return 1;
		}
	} else {
		var t = monster.a;
		switch (t) {
			case 0:
				return 6;
			case 1:
				return 6;
			case 2:
				return 6;
			case 3:
				return 6;
			case 4:
				return 6;
			case 5:
				return 6;
			case 6:
				return 6;
			case 7:
				return 6;
			case 8:
				return 4;
			case 9:
				return 6;
			case 10:
				return 6;
			case 11:
				return 10;
			case 12:
				return 6;
			case 13:
				return 10;
			case 14:
				return 6;
			case 15:
				return 6;
			case 16:
				return 6;
			case 17:
				return 6;
			case 18:
				return 6;
			case 19:
				return 6;
			case 20:
				return 6;
			case 21:
				return 6;
			case 22:
				return 6;
			case 23:
				return 10;
			case 24:
				return 10;
			case 25:
				return 10;
			case 26:
				return 6;
			case 27:
				return 4;
			case 28:
				return 6;
			case 29:
				return 6;
			case 30:
				return 6;
			case 31:
				return 6;
			case 32:
				return 6;
			case 33:
				return 4;
			case 34:
				return 4;
			case 35:
				return 4;
			case 36:
				return 10;
			default:
				return 10;
		}
	}
};
var $elm$core$Array$bitMask = 4294967295 >>> (32 - $elm$core$Array$shiftStep);
var $elm$core$Elm$JsArray$unsafeGet = _JsArray_unsafeGet;
var $elm$core$Array$getHelp = F3(
	function (shift, index, tree) {
		getHelp:
		while (true) {
			var pos = $elm$core$Array$bitMask & (index >>> shift);
			var _v0 = A2($elm$core$Elm$JsArray$unsafeGet, pos, tree);
			if (!_v0.$) {
				var subTree = _v0.a;
				var $temp$shift = shift - $elm$core$Array$shiftStep,
					$temp$index = index,
					$temp$tree = subTree;
				shift = $temp$shift;
				index = $temp$index;
				tree = $temp$tree;
				continue getHelp;
			} else {
				var values = _v0.a;
				return A2($elm$core$Elm$JsArray$unsafeGet, $elm$core$Array$bitMask & index, values);
			}
		}
	});
var $elm$core$Array$get = F2(
	function (index, _v0) {
		var len = _v0.a;
		var startShift = _v0.b;
		var tree = _v0.c;
		var tail = _v0.d;
		return ((index < 0) || (_Utils_cmp(index, len) > -1)) ? $elm$core$Maybe$Nothing : ((_Utils_cmp(
			index,
			$elm$core$Array$tailIndex(len)) > -1) ? $elm$core$Maybe$Just(
			A2($elm$core$Elm$JsArray$unsafeGet, $elm$core$Array$bitMask & index, tail)) : $elm$core$Maybe$Just(
			A3($elm$core$Array$getHelp, startShift, index, tree)));
	});
var $author$project$Game$getRoomsByCoord = F2(
	function (cells, _v0) {
		var x = _v0.a;
		var y = _v0.b;
		return A2(
			$elm$core$Maybe$andThen,
			function (colCell) {
				return A2(
					$elm$core$Maybe$map,
					function (cell) {
						return cell.O;
					},
					A2($elm$core$Array$get, x, colCell));
			},
			A2($elm$core$Array$get, y, cells));
	});
var $author$project$Scenario$BoardBounds = F4(
	function (minX, maxX, minY, maxY) {
		return {c$: maxX, c0: maxY, bm: minX, U: minY};
	});
var $author$project$BoardMapTile$MapTile = F8(
	function (ref, x, y, turns, originalX, originalY, passable, hidden) {
		return {aA: hidden, dk: originalX, dl: originalY, aG: passable, bJ: ref, dL: turns, ci: x, cj: y};
	});
var $elm$core$List$append = F2(
	function (xs, ys) {
		if (!ys.b) {
			return xs;
		} else {
			return A3($elm$core$List$foldr, $elm$core$List$cons, ys, xs);
		}
	});
var $elm$core$List$concat = function (lists) {
	return A3($elm$core$List$foldr, $elm$core$List$append, _List_Nil, lists);
};
var $author$project$Scenario$getMapTileListByObstacle = F2(
	function (mapTileData, boardOverlays) {
		return A2(
			$elm$core$List$map,
			function (_v0) {
				var x = _v0.a;
				var y = _v0.b;
				return A8($author$project$BoardMapTile$MapTile, mapTileData.bJ, x, y, mapTileData.dL, x, y, true, true);
			},
			A3(
				$elm$core$List$foldl,
				$elm$core$Basics$append,
				_List_Nil,
				A2(
					$elm$core$List$map,
					function (o) {
						return o.S;
					},
					boardOverlays)));
	});
var $author$project$BoardMapTile$indexedArrayXToMapTile = F4(
	function (ref, y, x, passable) {
		return A8($author$project$BoardMapTile$MapTile, ref, x, y, 0, x, y, passable, true);
	});
var $author$project$BoardMapTile$indexedArrayYToMapTile = F3(
	function (ref, y, arr) {
		return $elm$core$Array$toList(
			A2(
				$elm$core$Array$indexedMap,
				A2($author$project$BoardMapTile$indexedArrayXToMapTile, ref, y),
				arr));
	});
var $author$project$BoardMapTile$getMapTileListByRef = function (ref) {
	return $elm$core$List$concat(
		$elm$core$Array$toList(
			A2(
				$elm$core$Array$indexedMap,
				$author$project$BoardMapTile$indexedArrayYToMapTile(ref),
				$author$project$BoardMapTile$getGridByRef(ref))));
};
var $author$project$Scenario$normaliseAndRotateMapTile = F4(
	function (turns, refPoint, origin, mapTile) {
		var _v0 = A4(
			$author$project$Scenario$normaliseAndRotatePoint,
			turns,
			refPoint,
			origin,
			_Utils_Tuple2(mapTile.ci, mapTile.cj));
		var rotatedX = _v0.a;
		var rotatedY = _v0.b;
		return _Utils_update(
			mapTile,
			{dL: turns, ci: rotatedX, cj: rotatedY});
	});
var $elm$core$Tuple$second = function (_v0) {
	var y = _v0.b;
	return y;
};
var $author$project$Scenario$mapDoorDataToList = F5(
	function (prevRef, initRefPoint, initOrigin, initTurns, doorData) {
		var r = doorData.c;
		var origin = doorData.d;
		var mapTileData = doorData.e;
		var refPoint = A4($author$project$Scenario$normaliseAndRotatePoint, initTurns, initRefPoint, initOrigin, r);
		var doorTile = A8($author$project$BoardMapTile$MapTile, prevRef, refPoint.a, refPoint.b, initTurns, r.a, r.b, true, true);
		return A2(
			$elm$core$List$append,
			_List_fromArray(
				[doorTile]),
			A2(
				$author$project$Scenario$mapTileDataToList,
				mapTileData,
				$elm$core$Maybe$Just(
					_Utils_Tuple2(refPoint, origin))).a);
	});
var $author$project$Scenario$mapTileDataToList = F2(
	function (data, maybeTurnAxis) {
		var _v0 = function () {
			if (!maybeTurnAxis.$) {
				var _v2 = maybeTurnAxis.a;
				var r = _v2.a;
				var o = _v2.b;
				return _Utils_Tuple2(r, o);
			} else {
				return _Utils_Tuple2(
					_Utils_Tuple2(0, 0),
					_Utils_Tuple2(0, 0));
			}
		}();
		var refPoint = _v0.a;
		var origin = _v0.b;
		var doorTiles = $elm$core$List$concat(
			A2(
				$elm$core$List$map,
				A4($author$project$Scenario$mapDoorDataToList, data.bJ, refPoint, origin, data.dL),
				data.cD));
		var mapTiles = A2(
			$elm$core$List$map,
			A3($author$project$Scenario$normaliseAndRotateMapTile, data.dL, refPoint, origin),
			_Utils_ap(
				$author$project$BoardMapTile$getMapTileListByRef(data.bJ),
				A2($author$project$Scenario$getMapTileListByObstacle, data, data.bA)));
		var allTiles = _Utils_ap(mapTiles, doorTiles);
		var boundingBox = A3(
			$elm$core$List$foldl,
			F2(
				function (a, b) {
					return A4(
						$author$project$Scenario$BoardBounds,
						A2($elm$core$Basics$min, a.bm, b.bm),
						A2($elm$core$Basics$max, a.c$, b.c$),
						A2($elm$core$Basics$min, a.U, b.U),
						A2($elm$core$Basics$max, a.c0, b.c0));
				}),
			A4($author$project$Scenario$BoardBounds, 0, 0, 0, 0),
			A2(
				$elm$core$List$map,
				function (m) {
					return A4($author$project$Scenario$BoardBounds, m.ci, m.ci, m.cj, m.cj);
				},
				allTiles));
		return _Utils_Tuple2(allTiles, boundingBox);
	});
var $elm$core$List$maximum = function (list) {
	if (list.b) {
		var x = list.a;
		var xs = list.b;
		return $elm$core$Maybe$Just(
			A3($elm$core$List$foldl, $elm$core$Basics$max, x, xs));
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $elm$core$Dict$singleton = F2(
	function (key, value) {
		return A5($elm$core$Dict$RBNode_elm_builtin, 1, key, value, $elm$core$Dict$RBEmpty_elm_builtin, $elm$core$Dict$RBEmpty_elm_builtin);
	});
var $elm$core$Dict$union = F2(
	function (t1, t2) {
		return A3($elm$core$Dict$foldl, $elm$core$Dict$insert, t2, t1);
	});
var $author$project$Scenario$mapTileDataToOverlayList = function (data) {
	var maxId = function () {
		var _v7 = $elm$core$List$maximum(
			A2(
				$elm$core$List$map,
				function (o) {
					return o.ag;
				},
				data.bA));
		if (!_v7.$) {
			var i = _v7.a;
			return i + 1;
		} else {
			return 1;
		}
	}();
	var initData = function () {
		var _v1 = $author$project$BoardMapTile$refToString(data.bJ);
		if (!_v1.$) {
			var ref = _v1.a;
			return A2(
				$elm$core$Dict$singleton,
				ref,
				_Utils_Tuple2(
					_Utils_ap(
						data.bA,
						A2(
							$elm$core$List$indexedMap,
							F2(
								function (i, d) {
									var subType = d.a;
									var dir = d.b;
									var _v3 = d.c;
									var x = _v3.a;
									var y = _v3.b;
									var l = d.e;
									if ((subType.$ === 2) && (subType.b === 1)) {
										var _v5 = subType.b;
										var turns = function () {
											switch (dir) {
												case 4:
													return 1;
												case 5:
													return 2;
												default:
													return 0;
											}
										}();
										var coords2 = A3(
											$author$project$Hexagon$rotate,
											_Utils_Tuple2(x + 1, y),
											_Utils_Tuple2(x, y),
											turns);
										return A4(
											$author$project$BoardOverlay$BoardOverlay,
											A2(
												$author$project$BoardOverlay$Door,
												subType,
												_List_fromArray(
													[data.bJ, l.bJ])),
											maxId + i,
											dir,
											_List_fromArray(
												[
													_Utils_Tuple2(x, y),
													coords2
												]));
									} else {
										return A4(
											$author$project$BoardOverlay$BoardOverlay,
											A2(
												$author$project$BoardOverlay$Door,
												subType,
												_List_fromArray(
													[data.bJ, l.bJ])),
											maxId + i,
											dir,
											_List_fromArray(
												[
													_Utils_Tuple2(x, y)
												]));
									}
								}),
							data.cD)),
					data.bn));
		} else {
			return $elm$core$Dict$empty;
		}
	}();
	var doorData = A3(
		$elm$core$List$foldl,
		F2(
			function (a, b) {
				return A2($elm$core$Dict$union, a, b);
			}),
		$elm$core$Dict$empty,
		A2(
			$elm$core$List$map,
			function (d) {
				var map = d.e;
				return $author$project$Scenario$mapTileDataToOverlayList(map);
			},
			data.cD));
	return A2($elm$core$Dict$union, initData, doorData);
};
var $elm$random$Random$Generator = $elm$core$Basics$identity;
var $elm$random$Random$Seed = F2(
	function (a, b) {
		return {$: 0, a: a, b: b};
	});
var $elm$random$Random$next = function (_v0) {
	var state0 = _v0.a;
	var incr = _v0.b;
	return A2($elm$random$Random$Seed, ((state0 * 1664525) + incr) >>> 0, incr);
};
var $elm$core$Bitwise$xor = _Bitwise_xor;
var $elm$random$Random$peel = function (_v0) {
	var state = _v0.a;
	var word = (state ^ (state >>> ((state >>> 28) + 4))) * 277803737;
	return ((word >>> 22) ^ word) >>> 0;
};
var $elm$random$Random$int = F2(
	function (a, b) {
		return function (seed0) {
			var _v0 = (_Utils_cmp(a, b) < 0) ? _Utils_Tuple2(a, b) : _Utils_Tuple2(b, a);
			var lo = _v0.a;
			var hi = _v0.b;
			var range = (hi - lo) + 1;
			if (!((range - 1) & range)) {
				return _Utils_Tuple2(
					(((range - 1) & $elm$random$Random$peel(seed0)) >>> 0) + lo,
					$elm$random$Random$next(seed0));
			} else {
				var threshhold = (((-range) >>> 0) % range) >>> 0;
				var accountForBias = function (seed) {
					accountForBias:
					while (true) {
						var x = $elm$random$Random$peel(seed);
						var seedN = $elm$random$Random$next(seed);
						if (_Utils_cmp(x, threshhold) < 0) {
							var $temp$seed = seedN;
							seed = $temp$seed;
							continue accountForBias;
						} else {
							return _Utils_Tuple2((x % range) + lo, seedN);
						}
					}
				};
				return accountForBias(seed0);
			}
		};
	});
var $elm$core$Elm$JsArray$push = _JsArray_push;
var $elm$core$Elm$JsArray$singleton = _JsArray_singleton;
var $elm$core$Elm$JsArray$unsafeSet = _JsArray_unsafeSet;
var $elm$core$Array$insertTailInTree = F4(
	function (shift, index, tail, tree) {
		var pos = $elm$core$Array$bitMask & (index >>> shift);
		if (_Utils_cmp(
			pos,
			$elm$core$Elm$JsArray$length(tree)) > -1) {
			if (shift === 5) {
				return A2(
					$elm$core$Elm$JsArray$push,
					$elm$core$Array$Leaf(tail),
					tree);
			} else {
				var newSub = $elm$core$Array$SubTree(
					A4($elm$core$Array$insertTailInTree, shift - $elm$core$Array$shiftStep, index, tail, $elm$core$Elm$JsArray$empty));
				return A2($elm$core$Elm$JsArray$push, newSub, tree);
			}
		} else {
			var value = A2($elm$core$Elm$JsArray$unsafeGet, pos, tree);
			if (!value.$) {
				var subTree = value.a;
				var newSub = $elm$core$Array$SubTree(
					A4($elm$core$Array$insertTailInTree, shift - $elm$core$Array$shiftStep, index, tail, subTree));
				return A3($elm$core$Elm$JsArray$unsafeSet, pos, newSub, tree);
			} else {
				var newSub = $elm$core$Array$SubTree(
					A4(
						$elm$core$Array$insertTailInTree,
						shift - $elm$core$Array$shiftStep,
						index,
						tail,
						$elm$core$Elm$JsArray$singleton(value)));
				return A3($elm$core$Elm$JsArray$unsafeSet, pos, newSub, tree);
			}
		}
	});
var $elm$core$Array$unsafeReplaceTail = F2(
	function (newTail, _v0) {
		var len = _v0.a;
		var startShift = _v0.b;
		var tree = _v0.c;
		var tail = _v0.d;
		var originalTailLen = $elm$core$Elm$JsArray$length(tail);
		var newTailLen = $elm$core$Elm$JsArray$length(newTail);
		var newArrayLen = len + (newTailLen - originalTailLen);
		if (_Utils_eq(newTailLen, $elm$core$Array$branchFactor)) {
			var overflow = _Utils_cmp(newArrayLen >>> $elm$core$Array$shiftStep, 1 << startShift) > 0;
			if (overflow) {
				var newShift = startShift + $elm$core$Array$shiftStep;
				var newTree = A4(
					$elm$core$Array$insertTailInTree,
					newShift,
					len,
					newTail,
					$elm$core$Elm$JsArray$singleton(
						$elm$core$Array$SubTree(tree)));
				return A4($elm$core$Array$Array_elm_builtin, newArrayLen, newShift, newTree, $elm$core$Elm$JsArray$empty);
			} else {
				return A4(
					$elm$core$Array$Array_elm_builtin,
					newArrayLen,
					startShift,
					A4($elm$core$Array$insertTailInTree, startShift, len, newTail, tree),
					$elm$core$Elm$JsArray$empty);
			}
		} else {
			return A4($elm$core$Array$Array_elm_builtin, newArrayLen, startShift, tree, newTail);
		}
	});
var $elm$core$Array$push = F2(
	function (a, array) {
		var tail = array.d;
		return A2(
			$elm$core$Array$unsafeReplaceTail,
			A2($elm$core$Elm$JsArray$push, a, tail),
			array);
	});
var $elm$core$Elm$JsArray$appendN = _JsArray_appendN;
var $elm$core$Elm$JsArray$slice = _JsArray_slice;
var $elm$core$Array$appendHelpBuilder = F2(
	function (tail, builder) {
		var tailLen = $elm$core$Elm$JsArray$length(tail);
		var notAppended = ($elm$core$Array$branchFactor - $elm$core$Elm$JsArray$length(builder.g)) - tailLen;
		var appended = A3($elm$core$Elm$JsArray$appendN, $elm$core$Array$branchFactor, builder.g, tail);
		return (notAppended < 0) ? {
			h: A2(
				$elm$core$List$cons,
				$elm$core$Array$Leaf(appended),
				builder.h),
			e: builder.e + 1,
			g: A3($elm$core$Elm$JsArray$slice, notAppended, tailLen, tail)
		} : ((!notAppended) ? {
			h: A2(
				$elm$core$List$cons,
				$elm$core$Array$Leaf(appended),
				builder.h),
			e: builder.e + 1,
			g: $elm$core$Elm$JsArray$empty
		} : {h: builder.h, e: builder.e, g: appended});
	});
var $elm$core$List$drop = F2(
	function (n, list) {
		drop:
		while (true) {
			if (n <= 0) {
				return list;
			} else {
				if (!list.b) {
					return list;
				} else {
					var x = list.a;
					var xs = list.b;
					var $temp$n = n - 1,
						$temp$list = xs;
					n = $temp$n;
					list = $temp$list;
					continue drop;
				}
			}
		}
	});
var $elm$core$Array$sliceLeft = F2(
	function (from, array) {
		var len = array.a;
		var tree = array.c;
		var tail = array.d;
		if (!from) {
			return array;
		} else {
			if (_Utils_cmp(
				from,
				$elm$core$Array$tailIndex(len)) > -1) {
				return A4(
					$elm$core$Array$Array_elm_builtin,
					len - from,
					$elm$core$Array$shiftStep,
					$elm$core$Elm$JsArray$empty,
					A3(
						$elm$core$Elm$JsArray$slice,
						from - $elm$core$Array$tailIndex(len),
						$elm$core$Elm$JsArray$length(tail),
						tail));
			} else {
				var skipNodes = (from / $elm$core$Array$branchFactor) | 0;
				var helper = F2(
					function (node, acc) {
						if (!node.$) {
							var subTree = node.a;
							return A3($elm$core$Elm$JsArray$foldr, helper, acc, subTree);
						} else {
							var leaf = node.a;
							return A2($elm$core$List$cons, leaf, acc);
						}
					});
				var leafNodes = A3(
					$elm$core$Elm$JsArray$foldr,
					helper,
					_List_fromArray(
						[tail]),
					tree);
				var nodesToInsert = A2($elm$core$List$drop, skipNodes, leafNodes);
				if (!nodesToInsert.b) {
					return $elm$core$Array$empty;
				} else {
					var head = nodesToInsert.a;
					var rest = nodesToInsert.b;
					var firstSlice = from - (skipNodes * $elm$core$Array$branchFactor);
					var initialBuilder = {
						h: _List_Nil,
						e: 0,
						g: A3(
							$elm$core$Elm$JsArray$slice,
							firstSlice,
							$elm$core$Elm$JsArray$length(head),
							head)
					};
					return A2(
						$elm$core$Array$builderToArray,
						true,
						A3($elm$core$List$foldl, $elm$core$Array$appendHelpBuilder, initialBuilder, rest));
				}
			}
		}
	});
var $elm$core$Array$fetchNewTail = F4(
	function (shift, end, treeEnd, tree) {
		fetchNewTail:
		while (true) {
			var pos = $elm$core$Array$bitMask & (treeEnd >>> shift);
			var _v0 = A2($elm$core$Elm$JsArray$unsafeGet, pos, tree);
			if (!_v0.$) {
				var sub = _v0.a;
				var $temp$shift = shift - $elm$core$Array$shiftStep,
					$temp$end = end,
					$temp$treeEnd = treeEnd,
					$temp$tree = sub;
				shift = $temp$shift;
				end = $temp$end;
				treeEnd = $temp$treeEnd;
				tree = $temp$tree;
				continue fetchNewTail;
			} else {
				var values = _v0.a;
				return A3($elm$core$Elm$JsArray$slice, 0, $elm$core$Array$bitMask & end, values);
			}
		}
	});
var $elm$core$Array$hoistTree = F3(
	function (oldShift, newShift, tree) {
		hoistTree:
		while (true) {
			if ((_Utils_cmp(oldShift, newShift) < 1) || (!$elm$core$Elm$JsArray$length(tree))) {
				return tree;
			} else {
				var _v0 = A2($elm$core$Elm$JsArray$unsafeGet, 0, tree);
				if (!_v0.$) {
					var sub = _v0.a;
					var $temp$oldShift = oldShift - $elm$core$Array$shiftStep,
						$temp$newShift = newShift,
						$temp$tree = sub;
					oldShift = $temp$oldShift;
					newShift = $temp$newShift;
					tree = $temp$tree;
					continue hoistTree;
				} else {
					return tree;
				}
			}
		}
	});
var $elm$core$Array$sliceTree = F3(
	function (shift, endIdx, tree) {
		var lastPos = $elm$core$Array$bitMask & (endIdx >>> shift);
		var _v0 = A2($elm$core$Elm$JsArray$unsafeGet, lastPos, tree);
		if (!_v0.$) {
			var sub = _v0.a;
			var newSub = A3($elm$core$Array$sliceTree, shift - $elm$core$Array$shiftStep, endIdx, sub);
			return (!$elm$core$Elm$JsArray$length(newSub)) ? A3($elm$core$Elm$JsArray$slice, 0, lastPos, tree) : A3(
				$elm$core$Elm$JsArray$unsafeSet,
				lastPos,
				$elm$core$Array$SubTree(newSub),
				A3($elm$core$Elm$JsArray$slice, 0, lastPos + 1, tree));
		} else {
			return A3($elm$core$Elm$JsArray$slice, 0, lastPos, tree);
		}
	});
var $elm$core$Array$sliceRight = F2(
	function (end, array) {
		var len = array.a;
		var startShift = array.b;
		var tree = array.c;
		var tail = array.d;
		if (_Utils_eq(end, len)) {
			return array;
		} else {
			if (_Utils_cmp(
				end,
				$elm$core$Array$tailIndex(len)) > -1) {
				return A4(
					$elm$core$Array$Array_elm_builtin,
					end,
					startShift,
					tree,
					A3($elm$core$Elm$JsArray$slice, 0, $elm$core$Array$bitMask & end, tail));
			} else {
				var endIdx = $elm$core$Array$tailIndex(end);
				var depth = $elm$core$Basics$floor(
					A2(
						$elm$core$Basics$logBase,
						$elm$core$Array$branchFactor,
						A2($elm$core$Basics$max, 1, endIdx - 1)));
				var newShift = A2($elm$core$Basics$max, 5, depth * $elm$core$Array$shiftStep);
				return A4(
					$elm$core$Array$Array_elm_builtin,
					end,
					newShift,
					A3(
						$elm$core$Array$hoistTree,
						startShift,
						newShift,
						A3($elm$core$Array$sliceTree, startShift, endIdx, tree)),
					A4($elm$core$Array$fetchNewTail, startShift, end, endIdx, tree));
			}
		}
	});
var $elm$core$Array$translateIndex = F2(
	function (index, _v0) {
		var len = _v0.a;
		var posIndex = (index < 0) ? (len + index) : index;
		return (posIndex < 0) ? 0 : ((_Utils_cmp(posIndex, len) > 0) ? len : posIndex);
	});
var $elm$core$Array$slice = F3(
	function (from, to, array) {
		var correctTo = A2($elm$core$Array$translateIndex, to, array);
		var correctFrom = A2($elm$core$Array$translateIndex, from, array);
		return (_Utils_cmp(correctFrom, correctTo) > 0) ? $elm$core$Array$empty : A2(
			$elm$core$Array$sliceLeft,
			correctFrom,
			A2($elm$core$Array$sliceRight, correctTo, array));
	});
var $elm$random$Random$step = F2(
	function (_v0, seed) {
		var generator = _v0;
		return generator(seed);
	});
var $author$project$Game$orderRandomArrElement = F3(
	function (bucket, seed, original) {
		orderRandomArrElement:
		while (true) {
			if (!$elm$core$Array$length(original)) {
				return _Utils_Tuple2(bucket, seed);
			} else {
				var _v0 = A2(
					$elm$random$Random$step,
					A2(
						$elm$random$Random$int,
						0,
						$elm$core$Array$length(original) - 1),
					seed);
				var index = _v0.a;
				var newSeed = _v0.b;
				var slice1 = $elm$core$Array$toList(
					A3($elm$core$Array$slice, 0, index, original));
				var slice2 = $elm$core$Array$toList(
					A3(
						$elm$core$Array$slice,
						index + 1,
						$elm$core$Array$length(original),
						original));
				var _v1 = A2($elm$core$Array$get, index, original);
				if (!_v1.$) {
					var o = _v1.a;
					var $temp$bucket = A2($elm$core$Array$push, o, bucket),
						$temp$seed = newSeed,
						$temp$original = $elm$core$Array$fromList(
						_Utils_ap(slice1, slice2));
					bucket = $temp$bucket;
					seed = $temp$seed;
					original = $temp$original;
					continue orderRandomArrElement;
				} else {
					return _Utils_Tuple2(bucket, seed);
				}
			}
		}
	});
var $author$project$Game$assignIdentifier = F2(
	function (availableMonsters, p) {
		var _v0 = p.bJ;
		if ((_v0.$ === 2) && (!_v0.a.$)) {
			var monster = _v0.a.a;
			var _v1 = $author$project$Monster$monsterTypeToString(monster.m);
			if (!_v1.$) {
				var key = _v1.a;
				var _v2 = A2($elm$core$Dict$get, key, availableMonsters);
				if (!_v2.$) {
					var bucket = _v2.a;
					var _v3 = A2($elm$core$Array$get, 0, bucket);
					if (!_v3.$) {
						var id = _v3.a;
						return _Utils_Tuple2(
							_Utils_update(
								p,
								{
									bJ: $author$project$Game$AI(
										$author$project$Game$Enemy(
											_Utils_update(
												monster,
												{ag: id + 1})))
								}),
							A3(
								$elm$core$Dict$insert,
								key,
								A3(
									$elm$core$Array$slice,
									1,
									$elm$core$Array$length(bucket),
									bucket),
								availableMonsters));
					} else {
						return _Utils_Tuple2(
							_Utils_update(
								p,
								{
									bJ: $author$project$Game$AI(
										$author$project$Game$Enemy(
											_Utils_update(
												monster,
												{ag: 0})))
								}),
							availableMonsters);
					}
				} else {
					return _Utils_Tuple2(
						_Utils_update(
							p,
							{
								bJ: $author$project$Game$AI(
									$author$project$Game$Enemy(
										_Utils_update(
											monster,
											{ag: 0})))
							}),
						availableMonsters);
				}
			} else {
				return _Utils_Tuple2(
					_Utils_update(
						p,
						{
							bJ: $author$project$Game$AI(
								$author$project$Game$Enemy(
									_Utils_update(
										monster,
										{ag: 0})))
						}),
					availableMonsters);
			}
		} else {
			return _Utils_Tuple2(p, availableMonsters);
		}
	});
var $author$project$Game$assignIdentifiers = F3(
	function (availableMonsters, processed, monsters) {
		assignIdentifiers:
		while (true) {
			if (monsters.b) {
				var m = monsters.a;
				var rest = monsters.b;
				var _v1 = A2($author$project$Game$assignIdentifier, availableMonsters, m);
				var newM = _v1.a;
				var newBucket = _v1.b;
				var $temp$availableMonsters = newBucket,
					$temp$processed = A2($elm$core$List$cons, newM, processed),
					$temp$monsters = rest;
				availableMonsters = $temp$availableMonsters;
				processed = $temp$processed;
				monsters = $temp$monsters;
				continue assignIdentifiers;
			} else {
				return _Utils_Tuple2(processed, availableMonsters);
			}
		}
	});
var $elm$core$Array$foldl = F3(
	function (func, baseCase, _v0) {
		var tree = _v0.c;
		var tail = _v0.d;
		var helper = F2(
			function (node, acc) {
				if (!node.$) {
					var subTree = node.a;
					return A3($elm$core$Elm$JsArray$foldl, helper, acc, subTree);
				} else {
					var values = node.a;
					return A3($elm$core$Elm$JsArray$foldl, func, acc, values);
				}
			});
		return A3(
			$elm$core$Elm$JsArray$foldl,
			func,
			A3($elm$core$Elm$JsArray$foldl, helper, baseCase, tree),
			tail);
	});
var $author$project$Game$revealRoom = F2(
	function (room, game) {
		if (A2($elm$core$List$member, room, game.ap.ab)) {
			return game;
		} else {
			var state = game.ap;
			var roomCells = A2(
				$elm$core$List$map,
				function (_v12) {
					var c = _v12.b;
					return c;
				},
				A2(
					$elm$core$List$filter,
					function (_v11) {
						var cell = _v11.a;
						return cell.aG && A2($elm$core$List$member, room, cell.O);
					},
					$elm$core$Array$toList(
						A3(
							$elm$core$Array$foldl,
							F2(
								function (a, b) {
									return $elm$core$Array$fromList(
										_Utils_ap(
											$elm$core$Array$toList(a),
											$elm$core$Array$toList(b)));
								}),
							$elm$core$Array$empty,
							A2(
								$elm$core$Array$indexedMap,
								F2(
									function (y, arr) {
										return A2(
											$elm$core$Array$indexedMap,
											F2(
												function (x, cell) {
													return _Utils_Tuple2(
														cell,
														_Utils_Tuple2(x, y));
												}),
											arr);
									}),
								game.x)))));
			var ignoredPieces = A2(
				$elm$core$List$filterMap,
				function (p) {
					var _v10 = p.bJ;
					if ((_v10.$ === 2) && (!_v10.a.$)) {
						var e = _v10.a.a;
						return (A2(
							$elm$core$List$member,
							_Utils_Tuple2(p.ci, p.cj),
							roomCells) && (!e.ag)) ? $elm$core$Maybe$Nothing : $elm$core$Maybe$Just(p);
					} else {
						return $elm$core$Maybe$Just(p);
					}
				},
				game.ap.bD);
			var corridors = A2(
				$elm$core$List$filter,
				function (r) {
					return !_Utils_eq(r, room);
				},
				A3(
					$elm$core$List$foldl,
					$elm$core$Basics$append,
					_List_Nil,
					A2(
						$elm$core$List$filterMap,
						function (o) {
							var _v8 = o.bJ;
							if ((_v8.$ === 1) && (_v8.a.$ === 2)) {
								var _v9 = _v8.a;
								var refs = _v8.b;
								return $elm$core$Maybe$Just(refs);
							} else {
								return $elm$core$Maybe$Nothing;
							}
						},
						A2(
							$elm$core$List$filter,
							function (o) {
								var _v5 = o.bJ;
								if ((_v5.$ === 1) && (_v5.a.$ === 2)) {
									var _v6 = _v5.a;
									var m = _v6.a;
									var refs = _v5.b;
									if (!m) {
										return false;
									} else {
										return A2($elm$core$List$member, room, refs);
									}
								} else {
									return false;
								}
							},
							game.ap.bA))));
			var _v1 = function (_v3) {
				var m = _v3.a;
				var a = _v3.b;
				return _Utils_Tuple2(
					A2(
						$elm$core$List$filterMap,
						function (p) {
							var _v4 = p.bJ;
							if ((_v4.$ === 2) && (!_v4.a.$)) {
								var e = _v4.a.a;
								return (!(!e.ag)) ? $elm$core$Maybe$Just(p) : $elm$core$Maybe$Nothing;
							} else {
								return $elm$core$Maybe$Nothing;
							}
						},
						m),
					a);
			}(
				A3(
					$author$project$Game$assignIdentifiers,
					game.ap.t,
					_List_Nil,
					A2(
						$elm$core$List$filterMap,
						function (p) {
							var _v2 = p.bJ;
							if ((_v2.$ === 2) && (!_v2.a.$)) {
								var e = _v2.a.a;
								return (A2(
									$elm$core$List$member,
									_Utils_Tuple2(p.ci, p.cj),
									roomCells) && (!e.ag)) ? $elm$core$Maybe$Just(p) : $elm$core$Maybe$Nothing;
							} else {
								return $elm$core$Maybe$Nothing;
							}
						},
						game.ap.bD)));
			var assignedMonsters = _v1.a;
			var availableMonsters = _v1.b;
			var newGame = _Utils_update(
				game,
				{
					ap: _Utils_update(
						state,
						{
							t: availableMonsters,
							bD: _Utils_ap(ignoredPieces, assignedMonsters),
							ab: A2($elm$core$List$cons, room, state.ab)
						})
				});
			return A2($author$project$Game$revealRooms, newGame, corridors);
		}
	});
var $author$project$Game$revealRooms = F2(
	function (game, rooms) {
		revealRooms:
		while (true) {
			if (rooms.b) {
				var room = rooms.a;
				var rest = rooms.b;
				var $temp$game = A2($author$project$Game$revealRoom, room, game),
					$temp$rooms = rest;
				game = $temp$game;
				rooms = $temp$rooms;
				continue revealRooms;
			} else {
				return game;
			}
		}
	});
var $author$project$Game$None = {$: 0};
var $author$project$Game$filterByCoord = F3(
	function (x, y, overlay) {
		var _v0 = overlay.S;
		if (_v0.b) {
			var _v1 = _v0.a;
			var overlayX = _v1.a;
			var overlayY = _v1.b;
			return _Utils_eq(overlayX, x) && _Utils_eq(overlayY, y);
		} else {
			return false;
		}
	});
var $author$project$Game$filterMonsterLevel = F2(
	function (numPlayers, monster) {
		return (numPlayers < 3) ? (!(!monster.dM)) : ((numPlayers < 4) ? (!(!monster.dF)) : (!(!monster.cP)));
	});
var $author$project$Game$getLevelForMonster = F2(
	function (numPlayers, monster) {
		return (numPlayers < 3) ? monster.dM : ((numPlayers < 4) ? monster.dF : monster.cP);
	});
var $author$project$Game$getPieceFromMonster = F2(
	function (numPlayers, monster) {
		if (!monster.$) {
			var p = monster.a;
			var m = p.m;
			var level = A2($author$project$Game$getLevelForMonster, numPlayers, p);
			return (!level) ? A3($author$project$Game$Piece, $author$project$Game$None, 0, 0) : A3(
				$author$project$Game$Piece,
				$author$project$Game$AI(
					$author$project$Game$Enemy(
						_Utils_update(
							m,
							{bj: level}))),
				p.be,
				p.bf);
		} else {
			return A3($author$project$Game$Piece, $author$project$Game$None, 0, 0);
		}
	});
var $author$project$Game$mapOverlayCoord = F6(
	function (originalX, originalY, newX, newY, turns, overlay) {
		var _v0 = $author$project$Hexagon$oddRowToCube(
			_Utils_Tuple2(originalX, originalY));
		var oX = _v0.a;
		var oY = _v0.b;
		var oZ = _v0.c;
		var _v1 = $author$project$Hexagon$oddRowToCube(
			_Utils_Tuple2(newX, newY));
		var nX = _v1.a;
		var nY = _v1.b;
		var nZ = _v1.c;
		var diffX = nX - oX;
		var diffY = nY - oY;
		var diffZ = nZ - oZ;
		return _Utils_update(
			overlay,
			{
				S: A2(
					$elm$core$List$map,
					function (c) {
						var _v2 = $author$project$Hexagon$oddRowToCube(
							A3(
								$author$project$Hexagon$rotate,
								c,
								_Utils_Tuple2(originalX, originalY),
								turns));
						var x1 = _v2.a;
						var y1 = _v2.b;
						var z1 = _v2.c;
						return $author$project$Hexagon$cubeToOddRow(
							_Utils_Tuple3(diffX + x1, diffY + y1, diffZ + z1));
					},
					overlay.S)
			});
	});
var $author$project$Game$mapPieceCoord = F5(
	function (_v0, _v1, newX, newY, piece) {
		return _Utils_update(
			piece,
			{ci: newX, cj: newY});
	});
var $elm$core$Array$setHelp = F4(
	function (shift, index, value, tree) {
		var pos = $elm$core$Array$bitMask & (index >>> shift);
		var _v0 = A2($elm$core$Elm$JsArray$unsafeGet, pos, tree);
		if (!_v0.$) {
			var subTree = _v0.a;
			var newSub = A4($elm$core$Array$setHelp, shift - $elm$core$Array$shiftStep, index, value, subTree);
			return A3(
				$elm$core$Elm$JsArray$unsafeSet,
				pos,
				$elm$core$Array$SubTree(newSub),
				tree);
		} else {
			var values = _v0.a;
			var newLeaf = A3($elm$core$Elm$JsArray$unsafeSet, $elm$core$Array$bitMask & index, value, values);
			return A3(
				$elm$core$Elm$JsArray$unsafeSet,
				pos,
				$elm$core$Array$Leaf(newLeaf),
				tree);
		}
	});
var $elm$core$Array$set = F3(
	function (index, value, array) {
		var len = array.a;
		var startShift = array.b;
		var tree = array.c;
		var tail = array.d;
		return ((index < 0) || (_Utils_cmp(index, len) > -1)) ? array : ((_Utils_cmp(
			index,
			$elm$core$Array$tailIndex(len)) > -1) ? A4(
			$elm$core$Array$Array_elm_builtin,
			len,
			startShift,
			tree,
			A3($elm$core$Elm$JsArray$unsafeSet, $elm$core$Array$bitMask & index, value, tail)) : A4(
			$elm$core$Array$Array_elm_builtin,
			len,
			startShift,
			A4($elm$core$Array$setHelp, startShift, index, value, tree),
			tail));
	});
var $author$project$Game$setCellFromMapTile = F6(
	function (game, overlays, offsetX, offsetY, tile, seed) {
		var y = tile.cj - offsetY;
		var x = tile.ci - offsetX;
		var state = game.ap;
		var rowArr = A2($elm$core$Array$get, y, game.x);
		var refString = A2(
			$elm$core$Maybe$withDefault,
			'',
			$author$project$BoardMapTile$refToString(tile.bJ));
		var _v0 = function () {
			var _v1 = A2($elm$core$Dict$get, refString, overlays);
			if (!_v1.$) {
				var _v2 = _v1.a;
				var o = _v2.a;
				var m = _v2.b;
				return _Utils_Tuple2(
					A2(
						$elm$core$List$map,
						A5($author$project$Game$mapOverlayCoord, tile.dk, tile.dl, x, y, tile.dL),
						A2(
							$elm$core$List$filter,
							A2($author$project$Game$filterByCoord, tile.dk, tile.dl),
							o)),
					A5(
						$author$project$Game$mapPieceCoord,
						tile.dk,
						tile.dl,
						x,
						y,
						A2(
							$author$project$Game$getPieceFromMonster,
							$elm$core$List$length(game.ap.an),
							$elm$core$List$head(
								A2(
									$elm$core$List$filter,
									function (f) {
										return _Utils_eq(f.be, tile.dk) && _Utils_eq(f.bf, tile.dl);
									},
									A2(
										$elm$core$List$filter,
										$author$project$Game$filterMonsterLevel(
											$elm$core$List$length(game.ap.an)),
										m))))));
			} else {
				return _Utils_Tuple2(
					_List_Nil,
					A3($author$project$Game$Piece, $author$project$Game$None, 0, 0));
			}
		}();
		var boardOverlays = _v0.a;
		var piece = _v0.b;
		var doorRefs = A3(
			$elm$core$List$foldl,
			$elm$core$Basics$append,
			_List_Nil,
			A2(
				$elm$core$List$filterMap,
				function (o) {
					var _v12 = o.bJ;
					if (_v12.$ === 1) {
						var refs = _v12.b;
						return $elm$core$Maybe$Just(refs);
					} else {
						return $elm$core$Maybe$Nothing;
					}
				},
				boardOverlays));
		var newBoard = function () {
			if (!rowArr.$) {
				var yRow = rowArr.a;
				var cell = A2($elm$core$Array$get, x, yRow);
				if (!cell.$) {
					var foundCell = cell.a;
					var newCell = _Utils_update(
						foundCell,
						{
							aG: (!foundCell.aG) ? tile.aG : true,
							O: A2(
								$elm_community$list_extra$List$Extra$uniqueBy,
								function (r) {
									return A2(
										$elm$core$Maybe$withDefault,
										'',
										$author$project$BoardMapTile$refToString(r));
								},
								A2(
									$elm$core$List$cons,
									tile.bJ,
									_Utils_ap(doorRefs, foundCell.O)))
						});
					return A3(
						$elm$core$Array$set,
						y,
						A3($elm$core$Array$set, x, newCell, yRow),
						game.x);
				} else {
					return game.x;
				}
			} else {
				return game.x;
			}
		}();
		var _v3 = function () {
			var _v4 = piece.bJ;
			if ((_v4.$ === 2) && (!_v4.a.$)) {
				var m = _v4.a.a;
				return function (_v5) {
					var a = _v5.a;
					var s = _v5.b;
					return _Utils_Tuple2(
						$elm$core$Maybe$Just(
							_Utils_Tuple2(
								A2(
									$elm$core$Maybe$withDefault,
									'',
									$author$project$Monster$monsterTypeToString(m.m)),
								a)),
						s);
				}(
					A3(
						$author$project$Game$orderRandomArrElement,
						$elm$core$Array$empty,
						seed,
						A2(
							$elm$core$Array$initialize,
							$author$project$Monster$getMonsterBucketSize(m.m),
							$elm$core$Basics$identity)));
			} else {
				return _Utils_Tuple2($elm$core$Maybe$Nothing, seed);
			}
		}();
		var monsterBucket = _v3.a;
		var newSeed = _v3.b;
		var newGameState = _Utils_update(
			state,
			{
				t: function () {
					if (!monsterBucket.$) {
						var b = monsterBucket.a;
						return $elm$core$Dict$fromList(
							A2(
								$elm$core$List$filter,
								function (_v8) {
									var k = _v8.a;
									return k !== '';
								},
								A2(
									$elm$core$List$cons,
									b,
									$elm$core$Dict$toList(game.ap.t))));
					} else {
						return game.ap.t;
					}
				}(),
				bA: _Utils_ap(game.ap.bA, boardOverlays),
				bD: _Utils_ap(
					game.ap.bD,
					function () {
						var _v9 = piece.bJ;
						if (!_v9.$) {
							return _List_Nil;
						} else {
							return _List_fromArray(
								[piece]);
						}
					}())
			});
		var _v6 = ((!tile.dk) && (!tile.dl)) ? _Utils_Tuple2(
			true,
			A2(
				$elm$core$List$cons,
				A3(
					$author$project$Game$RoomData,
					tile.bJ,
					_Utils_Tuple2(x, y),
					tile.dL),
				game.bT)) : _Utils_Tuple2(false, game.bT);
		var isOrigin = _v6.a;
		var newOrigins = _v6.b;
		return (tile.aG || (($elm$core$List$length(doorRefs) > 0) || isOrigin)) ? _Utils_Tuple2(
			_Utils_update(
				game,
				{bT: newOrigins, ap: newGameState, x: newBoard}),
			newSeed) : _Utils_Tuple2(
			_Utils_update(
				game,
				{b$: newSeed}),
			newSeed);
	});
var $author$project$Game$setCellsFromMapTiles = F6(
	function (mapTileList, overlays, offsetX, offsetY, seed, game) {
		setCellsFromMapTiles:
		while (true) {
			if (mapTileList.b) {
				var head = mapTileList.a;
				var rest = mapTileList.b;
				var _v1 = A6($author$project$Game$setCellFromMapTile, game, overlays, offsetX, offsetY, head, seed);
				var newGame = _v1.a;
				var newSeed = _v1.b;
				var $temp$mapTileList = rest,
					$temp$overlays = overlays,
					$temp$offsetX = offsetX,
					$temp$offsetY = offsetY,
					$temp$seed = newSeed,
					$temp$game = newGame;
				mapTileList = $temp$mapTileList;
				overlays = $temp$overlays;
				offsetX = $temp$offsetX;
				offsetY = $temp$offsetY;
				seed = $temp$seed;
				game = $temp$game;
				continue setCellsFromMapTiles;
			} else {
				return game;
			}
		}
	});
var $author$project$Game$generateGameMap = F5(
	function (gameStateScenario, scenario, roomCode, players, seed) {
		var initOverlays = $author$project$Scenario$mapTileDataToOverlayList(scenario.bl);
		var availableMonsters = $elm$core$Dict$fromList(
			A2(
				$elm$core$List$map,
				function (_v3) {
					var k = _v3.a;
					var v = _v3.b;
					return _Utils_Tuple2(
						k,
						A3($author$project$Game$orderRandomArrElement, $elm$core$Array$empty, seed, v).a);
				},
				A2(
					$elm$core$List$filter,
					function (_v2) {
						var k = _v2.a;
						return k !== '';
					},
					A2(
						$elm$core$List$map,
						function (m) {
							return _Utils_Tuple2(
								A2(
									$elm$core$Maybe$withDefault,
									'',
									$author$project$Monster$monsterTypeToString(m)),
								A2(
									$elm$core$Array$initialize,
									$author$project$Monster$getMonsterBucketSize(m),
									$elm$core$Basics$identity));
						},
						scenario.cm))));
		var initGameState = A8($author$project$Game$GameState, gameStateScenario, players, 0, _List_Nil, _List_Nil, _List_Nil, availableMonsters, roomCode);
		var _v0 = A2($author$project$Scenario$mapTileDataToList, scenario.bl, $elm$core$Maybe$Nothing);
		var mapTiles = _v0.a;
		var bounds = _v0.b;
		var arrSize = (A2(
			$elm$core$Basics$max,
			$elm$core$Basics$abs(bounds.c$ - bounds.bm),
			$elm$core$Basics$abs(bounds.c0 - bounds.U)) + 1) + (((bounds.U & 1) === 1) ? 1 : 0);
		var initMap = A2(
			$elm$core$Array$initialize,
			arrSize,
			$elm$core$Basics$always(
				A2(
					$elm$core$Array$initialize,
					arrSize,
					$elm$core$Basics$always(
						A2($author$project$Game$Cell, _List_Nil, false)))));
		var offsetY = ((bounds.U & 1) === 1) ? (bounds.U - 1) : bounds.U;
		var initGame = $author$project$Game$ensureUniqueOverlays(
			A6(
				$author$project$Game$setCellsFromMapTiles,
				mapTiles,
				initOverlays,
				bounds.bm,
				offsetY,
				seed,
				A5($author$project$Game$Game, initGameState, scenario, seed, _List_Nil, initMap)));
		var startRooms = A2(
			$elm_community$list_extra$List$Extra$uniqueBy,
			function (ref) {
				return A2(
					$elm$core$Maybe$withDefault,
					'',
					$author$project$BoardMapTile$refToString(ref));
			},
			A3(
				$elm$core$List$foldl,
				$elm$core$Basics$append,
				_List_Nil,
				A2(
					$elm$core$List$filterMap,
					$author$project$Game$getRoomsByCoord(initGame.x),
					A3(
						$elm$core$List$foldl,
						$elm$core$Basics$append,
						_List_Nil,
						A2(
							$elm$core$List$filterMap,
							function (o) {
								var _v1 = o.bJ;
								if (_v1.$ === 6) {
									return $elm$core$Maybe$Just(o.S);
								} else {
									return $elm$core$Maybe$Nothing;
								}
							},
							initGame.ap.bA)))));
		return A2($author$project$Game$revealRooms, initGame, startRooms);
	});
var $author$project$Creator$mapCoordsToRoom = F4(
	function (ref, turns, origin, roomCellData) {
		var roomOrigin = A2(
			$elm$core$Maybe$andThen,
			function (_v4) {
				var k = _v4.a;
				return $elm$core$Maybe$Just(k);
			},
			A2(
				$elm$core$Maybe$andThen,
				function (l) {
					return $elm$core$List$head(l);
				},
				A2(
					$elm$core$Maybe$map,
					function (_v1) {
						var d = _v1.b;
						return A2(
							$elm$core$List$filter,
							function (_v2) {
								var _v3 = _v2.b;
								var o = _v3.a;
								return _Utils_eq(
									o,
									_Utils_Tuple2(0, 0));
							},
							$elm$core$Dict$toList(d));
					},
					$elm$core$List$head(
						A2(
							$elm$core$List$filter,
							function (_v0) {
								var r = _v0.a;
								return _Utils_eq(r, ref);
							},
							roomCellData)))));
		return A2(
			$elm$core$Maybe$map,
			function (o) {
				var rotatedCell = A3($author$project$Hexagon$rotate, origin, o, 6 - turns);
				var y = rotatedCell.b - o.b;
				var x = ((((y & 1) === 1) && (!(rotatedCell.b & 1))) ? (-1) : 0) + (rotatedCell.a - o.a);
				return _Utils_Tuple2(x, y);
			},
			roomOrigin);
	});
var $author$project$Creator$assignDoorData = F6(
	function (mapTile, otherMapTiles, allMapTiles, doorsForThisTile, doorsForOtherTiles, roomCellMap) {
		var _v0 = A3(
			$elm$core$List$foldl,
			F2(
				function (door, _v1) {
					var od = _v1.a;
					var om = _v1.b;
					var dd = _v1.c;
					var _v2 = _Utils_Tuple2(
						$elm$core$List$head(door.S),
						door.bJ);
					if ((!_v2.a.$) && (_v2.b.$ === 1)) {
						var cell = _v2.a.a;
						var _v3 = _v2.b;
						var subType = _v3.a;
						var connections = _v3.b;
						var maybeConnectingRoom = A2(
							$elm$core$Maybe$andThen,
							function (r) {
								return $elm$core$List$head(
									A2(
										$elm$core$List$filter,
										function (m) {
											return _Utils_eq(m.bJ, r);
										},
										allMapTiles));
							},
							$elm$core$List$head(
								A2(
									$elm$core$List$filter,
									function (r) {
										return !_Utils_eq(r, mapTile.bJ);
									},
									connections)));
						if (!maybeConnectingRoom.$) {
							var connectingRoom = maybeConnectingRoom.a;
							var roomCoords = A4($author$project$Creator$mapCoordsToRoom, mapTile.bJ, mapTile.dL, cell, roomCellMap);
							var connectingCoords = A4($author$project$Creator$mapCoordsToRoom, connectingRoom.bJ, connectingRoom.dL, cell, roomCellMap);
							var _v5 = function () {
								var _v6 = $elm$core$List$head(
									A2(
										$elm$core$List$filter,
										function (m) {
											return _Utils_eq(m.bJ, connectingRoom.bJ);
										},
										om));
								if (!_v6.$) {
									var m = _v6.a;
									var nonConnectingDoors = A2(
										$elm$core$List$filter,
										function (o) {
											var _v8 = o.bJ;
											if (_v8.$ === 1) {
												var c = _v8.b;
												return !A2(
													$elm$core$List$any,
													function (c1) {
														return _Utils_eq(c1, m.bJ);
													},
													c);
											} else {
												return false;
											}
										},
										od);
									var connectingDoors = A2(
										$elm$core$List$filter,
										function (o) {
											var _v7 = o.bJ;
											if (_v7.$ === 1) {
												var c = _v7.b;
												return A2(
													$elm$core$List$any,
													function (c1) {
														return _Utils_eq(c1, m.bJ);
													},
													c);
											} else {
												return false;
											}
										},
										od);
									return A6($author$project$Creator$assignDoorData, m, om, allMapTiles, connectingDoors, nonConnectingDoors, roomCellMap);
								} else {
									return _Utils_Tuple3(
										A5($author$project$Scenario$MapTileData, connectingRoom.bJ, _List_Nil, _List_Nil, _List_Nil, connectingRoom.dL),
										om,
										od);
								}
							}();
							var connectingMapTile = _v5.a;
							var om2 = _v5.b;
							var od2 = _v5.c;
							var _v9 = _Utils_Tuple2(roomCoords, connectingCoords);
							if ((!_v9.a.$) && (!_v9.b.$)) {
								var r1 = _v9.a.a;
								var r2 = _v9.b.a;
								var newDoorData = A5($author$project$Scenario$DoorLink, subType, door.aw, r1, r2, connectingMapTile);
								return _Utils_Tuple3(
									od2,
									om2,
									A2($elm$core$List$cons, newDoorData, dd));
							} else {
								return _Utils_Tuple3(od, om, dd);
							}
						} else {
							return _Utils_Tuple3(od, om, dd);
						}
					} else {
						return _Utils_Tuple3(od, om, dd);
					}
				}),
			_Utils_Tuple3(doorsForOtherTiles, otherMapTiles, _List_Nil),
			doorsForThisTile);
		var remainingDoors = _v0.a;
		var doorData = _v0.c;
		return _Utils_Tuple3(
			_Utils_update(
				mapTile,
				{cD: doorData}),
			otherMapTiles,
			remainingDoors);
	});
var $author$project$Creator$assignMapTileData = F3(
	function (overlays, monsters, roomData) {
		var overlayData = A2(
			$elm$core$List$map,
			function (_v3) {
				var o = _v3.b;
				return o;
			},
			A2(
				$elm$core$List$filter,
				function (_v2) {
					var ref = _v2.a;
					return _Utils_eq(ref, roomData.bJ);
				},
				overlays));
		var monsterData = A2(
			$elm$core$List$map,
			function (_v1) {
				var m = _v1.b;
				return m;
			},
			A2(
				$elm$core$List$filter,
				function (_v0) {
					var ref = _v0.a;
					return _Utils_eq(ref, roomData.bJ);
				},
				monsters));
		return A5($author$project$Scenario$MapTileData, roomData.bJ, _List_Nil, overlayData, monsterData, roomData.dL);
	});
var $author$project$Creator$generateMapTileData = F5(
	function (roomDataList, doors, overlays, monsters, roomCellMap) {
		var rooms = $elm$core$List$reverse(
			A2(
				$elm$core$List$sortBy,
				function (m) {
					var startingLocations = $elm$core$List$length(
						A2(
							$elm$core$List$filter,
							function (o) {
								return _Utils_eq(o.bJ, $author$project$BoardOverlay$StartingLocation);
							},
							m.bA));
					var numDoors = $elm$core$List$length(
						A2(
							$elm$core$List$filter,
							function (d) {
								var _v4 = d.bJ;
								if (_v4.$ === 1) {
									var connections = _v4.b;
									return A2(
										$elm$core$List$any,
										function (c) {
											return _Utils_eq(c, m.bJ);
										},
										connections);
								} else {
									return false;
								}
							},
							doors));
					return numDoors + startingLocations;
				},
				A2(
					$elm$core$List$map,
					A2($author$project$Creator$assignMapTileData, overlays, monsters),
					roomDataList)));
		if (rooms.b) {
			var firstRoom = rooms.a;
			var rest = rooms.b;
			var remainingDoors = A2(
				$elm$core$List$filter,
				function (o) {
					var _v3 = o.bJ;
					if (_v3.$ === 1) {
						var connections = _v3.b;
						return !A2(
							$elm$core$List$any,
							function (c) {
								return _Utils_eq(c, firstRoom.bJ);
							},
							connections);
					} else {
						return false;
					}
				},
				doors);
			var doorsForThisTile = A2(
				$elm$core$List$filter,
				function (o) {
					var _v2 = o.bJ;
					if (_v2.$ === 1) {
						var connections = _v2.b;
						return A2(
							$elm$core$List$any,
							function (c) {
								return _Utils_eq(c, firstRoom.bJ);
							},
							connections);
					} else {
						return false;
					}
				},
				doors);
			var _v1 = A6($author$project$Creator$assignDoorData, firstRoom, rest, rooms, doorsForThisTile, remainingDoors, roomCellMap);
			var mapTileData = _v1.a;
			return $elm$core$Result$Ok(mapTileData);
		} else {
			return $elm$core$Result$Err('No rooms have been added');
		}
	});
var $author$project$Creator$generateScenario = F5(
	function (title, rooms, overlays, monsters, roomCellMap) {
		var _v0 = $elm$core$List$head(rooms);
		if (!_v0.$) {
			var overlaysWithoutDoors = A2(
				$elm$core$List$filter,
				function (_v4) {
					var o = _v4.b;
					var _v5 = o.bJ;
					if (_v5.$ === 1) {
						return false;
					} else {
						return true;
					}
				},
				overlays);
			var doors = A2(
				$elm$core$List$filterMap,
				function (_v2) {
					var o = _v2.b;
					var _v3 = o.bJ;
					if (_v3.$ === 1) {
						return $elm$core$Maybe$Just(o);
					} else {
						return $elm$core$Maybe$Nothing;
					}
				},
				overlays);
			var mapTileModel = A5($author$project$Creator$generateMapTileData, rooms, doors, overlaysWithoutDoors, monsters, roomCellMap);
			if (!mapTileModel.$) {
				var exportableMap = mapTileModel.a;
				return $elm$core$Result$Ok(
					A5($author$project$Scenario$Scenario, 0, title, exportableMap, 0, _List_Nil));
			} else {
				var e = mapTileModel.a;
				return $elm$core$Result$Err(e);
			}
		} else {
			return $elm$core$Result$Err('No map tile data could be found');
		}
	});
var $elm$json$Json$Encode$bool = _Json_wrap;
var $author$project$Creator$getCellFromPoint = _Platform_outgoingPort(
	'getCellFromPoint',
	function ($) {
		var a = $.a;
		var b = $.b;
		var c = $.c;
		return A2(
			$elm$json$Json$Encode$list,
			$elm$core$Basics$identity,
			_List_fromArray(
				[
					$elm$json$Json$Encode$float(a),
					$elm$json$Json$Encode$float(b),
					$elm$json$Json$Encode$bool(c)
				]));
	});
var $author$project$Creator$getConfirmCreateNew = _Platform_outgoingPort(
	'getConfirmCreateNew',
	function ($) {
		return $elm$json$Json$Encode$null;
	});
var $author$project$Creator$getContextPosition = _Platform_outgoingPort(
	'getContextPosition',
	function ($) {
		var a = $.a;
		var b = $.b;
		return A2(
			$elm$json$Json$Encode$list,
			$elm$core$Basics$identity,
			_List_fromArray(
				[
					$elm$json$Json$Encode$int(a),
					$elm$json$Json$Encode$int(b)
				]));
	});
var $elm$random$Random$initialSeed = function (x) {
	var _v0 = $elm$random$Random$next(
		A2($elm$random$Random$Seed, 0, 1013904223));
	var state1 = _v0.a;
	var incr = _v0.b;
	var state2 = (state1 + x) >>> 0;
	return $elm$random$Random$next(
		A2($elm$random$Random$Seed, state2, incr));
};
var $author$project$Creator$mapPieceToScenarioMonster = F5(
	function (newPiece, monsterList, origin, _v0, piece) {
		var targetX = _v0.a;
		var targetY = _v0.b;
		var _v1 = _Utils_Tuple3(piece.bJ, piece.ci, piece.cj);
		if ((_v1.a.$ === 2) && (!_v1.a.a.$)) {
			var monster = _v1.a.a.a;
			var x = _v1.b;
			var y = _v1.c;
			if (_Utils_eq(piece, newPiece)) {
				var existingMonster = A2(
					$elm$core$Maybe$withDefault,
					A6($author$project$Scenario$ScenarioMonster, monster, 0, 0, 1, 1, 1),
					$elm$core$List$head(
						A2(
							$elm$core$List$filter,
							function (m) {
								return _Utils_eq(
									$elm$core$Maybe$Just(
										_Utils_Tuple2(m.be, m.bf)),
									origin);
							},
							monsterList)));
				return $elm$core$Maybe$Just(
					_Utils_update(
						existingMonster,
						{be: targetX, bf: targetY}));
			} else {
				return $elm$core$List$head(
					A2(
						$elm$core$List$filter,
						function (m) {
							return _Utils_eq(m.be, x) && _Utils_eq(m.bf, y);
						},
						monsterList));
			}
		} else {
			return $elm$core$Maybe$Nothing;
		}
	});
var $elm$core$Dict$member = F2(
	function (key, dict) {
		var _v0 = A2($elm$core$Dict$get, key, dict);
		if (!_v0.$) {
			return true;
		} else {
			return false;
		}
	});
var $author$project$Game$moveOverlayWithoutState = F5(
	function (overlay, fromCoords, prevCoords, _v0, overlays) {
		var toX = _v0.a;
		var toY = _v0.b;
		var newOverlays = function () {
			if (!fromCoords.$) {
				return A2(
					$elm$core$List$filter,
					function (o) {
						return !_Utils_eq(o.ag, overlay.ag);
					},
					overlays);
			} else {
				return overlays;
			}
		}();
		var _v1 = function () {
			if (!fromCoords.$) {
				var _v3 = fromCoords.a;
				var oX = _v3.a;
				var oY = _v3.b;
				return $author$project$Hexagon$oddRowToCube(
					_Utils_Tuple2(oX, oY));
			} else {
				return _Utils_Tuple3(0, 0, 0);
			}
		}();
		var fromX = _v1.a;
		var fromY = _v1.b;
		var fromZ = _v1.c;
		var _v4 = function () {
			if (!prevCoords.$) {
				var p = prevCoords.a;
				var _v6 = $author$project$Hexagon$oddRowToCube(p);
				var pX = _v6.a;
				var pY = _v6.b;
				var pZ = _v6.c;
				return _Utils_Tuple3(fromX - pX, fromY - pY, fromZ - pZ);
			} else {
				return _Utils_Tuple3(0, 0, 0);
			}
		}();
		var prevDiffX = _v4.a;
		var prevDiffY = _v4.b;
		var prevDiffZ = _v4.c;
		var _v7 = function () {
			var _v8 = function () {
				if (!fromCoords.$) {
					var _v10 = $author$project$Hexagon$oddRowToCube(
						_Utils_Tuple2(toX, toY));
					var newX = _v10.a;
					var newY = _v10.b;
					var newZ = _v10.c;
					return _Utils_Tuple3(newX - fromX, newY - fromY, newZ - fromZ);
				} else {
					return $author$project$Hexagon$oddRowToCube(
						_Utils_Tuple2(toX, toY));
				}
			}();
			var dX = _v8.a;
			var dY = _v8.b;
			var dZ = _v8.c;
			return _Utils_Tuple3(dX + prevDiffX, dY + prevDiffY, dZ + prevDiffZ);
		}();
		var diffX = _v7.a;
		var diffY = _v7.b;
		var diffZ = _v7.c;
		var moveCells = function (c) {
			var _v11 = $author$project$Hexagon$oddRowToCube(c);
			var cX = _v11.a;
			var cY = _v11.b;
			var cZ = _v11.c;
			return $author$project$Hexagon$cubeToOddRow(
				_Utils_Tuple3(cX + diffX, cY + diffY, cZ + diffZ));
		};
		var newOverlay = _Utils_update(
			overlay,
			{
				S: A2($elm$core$List$map, moveCells, overlay.S)
			});
		return _Utils_Tuple3(
			newOverlays,
			newOverlay,
			$elm$core$Maybe$Just(
				_Utils_Tuple2(toX, toY)));
	});
var $author$project$Game$removePiece = F2(
	function (pieceToRemove, comparePiece) {
		return !_Utils_eq(pieceToRemove.bJ, comparePiece.bJ);
	});
var $author$project$Game$movePieceWithoutState = F4(
	function (piece, fromCoords, _v0, pieces) {
		var toX = _v0.a;
		var toY = _v0.b;
		var newPieces = function () {
			if (!fromCoords.$) {
				var _v2 = fromCoords.a;
				var fromX = _v2.a;
				var fromY = _v2.b;
				return A2(
					$elm$core$List$filter,
					$author$project$Game$removePiece(
						_Utils_update(
							piece,
							{ci: fromX, cj: fromY})),
					pieces);
			} else {
				return pieces;
			}
		}();
		var newPiece = _Utils_update(
			piece,
			{ci: toX, cj: toY});
		return A2(
			$elm$core$List$any,
			function (p) {
				return _Utils_eq(p.ci, toX) && _Utils_eq(p.cj, toY);
			},
			newPieces) ? _Utils_Tuple2(pieces, piece) : _Utils_Tuple2(
			A2($elm$core$List$cons, newPiece, newPieces),
			newPiece);
	});
var $author$project$Creator$moveRoom = F2(
	function (target, room) {
		var roomData = room.a$;
		var _v0 = $author$project$Creator$calculateRoomCells(
			_Utils_update(
				roomData,
				{dj: target}));
		var cells = _v0.a;
		var newOrigin = _v0.b;
		var _v1 = function () {
			var _v2 = _Utils_Tuple2(newOrigin, target);
			var _v3 = _v2.a;
			var oX = _v3.a;
			var oY = _v3.b;
			var _v4 = _v2.b;
			var tX = _v4.a;
			var tY = _v4.b;
			var _v5 = _Utils_Tuple2(tX - oX, tY - oY);
			var dX = _v5.a;
			var dY = _v5.b;
			return _Utils_Tuple2((target.a - room.a$.dj.a) - dX, (target.b - room.a$.dj.b) - dY);
		}();
		var deltaX = _v1.a;
		var deltaY = _v1.b;
		return _Utils_Tuple2(
			cells,
			_Utils_update(
				room,
				{
					a$: _Utils_update(
						roomData,
						{dj: newOrigin}),
					bU: _Utils_Tuple2(room.bU.a + deltaX, room.bU.b + deltaY)
				}));
	});
var $mpizenberg$elm_pointer_events$Html$Events$Extra$Drag$dropEffectToString = function (dropEffect) {
	switch (dropEffect) {
		case 0:
			return 'none';
		case 1:
			return 'move';
		case 2:
			return 'copy';
		default:
			return 'link';
	}
};
var $mpizenberg$elm_pointer_events$Html$Events$Extra$Drag$overPortData = F2(
	function (dropEffect, value) {
		return {
			cF: $mpizenberg$elm_pointer_events$Html$Events$Extra$Drag$dropEffectToString(dropEffect),
			a6: value
		};
	});
var $author$project$Creator$rotateRoom = F2(
	function (i, extRoom) {
		return A3(
			$elm$core$List$foldr,
			F2(
				function (_v0, _v1) {
					var room = _v1.b;
					var turns = (room.a$.dL === 5) ? 0 : (room.a$.dL + 1);
					var tmpRoom = room.a$;
					var origin = A3($author$project$Hexagon$rotate, room.a$.dj, room.bU, 1);
					var newRoom = _Utils_update(
						tmpRoom,
						{dj: origin, dL: turns});
					var _v2 = $author$project$Creator$calculateRoomCells(
						_Utils_update(
							tmpRoom,
							{dj: origin, dL: turns}));
					var cells = _v2.a;
					var newOrigin = _v2.b;
					var newRotationPoint = function () {
						var _v3 = _Utils_Tuple2(origin, newOrigin);
						var _v4 = _v3.a;
						var oX = _v4.a;
						var oY = _v4.b;
						var _v5 = _v3.b;
						var tX = _v5.a;
						var tY = _v5.b;
						var _v6 = _Utils_Tuple2(tX - oX, tY - oY);
						var dX = _v6.a;
						var dY = _v6.b;
						return _Utils_Tuple2(room.bU.a + dX, room.bU.b + dY);
					}();
					return _Utils_Tuple2(
						cells,
						_Utils_update(
							room,
							{
								a$: _Utils_update(
									newRoom,
									{dj: newOrigin}),
								bU: newRotationPoint
							}));
				}),
			_Utils_Tuple2(
				_Utils_Tuple2(62, $elm$core$Dict$empty),
				extRoom),
			A2($elm$core$List$range, 1, i));
	});
var $author$project$SharedSync$encodeCoords = function (_v0) {
	var x = _v0.a;
	var y = _v0.b;
	return _List_fromArray(
		[
			_Utils_Tuple2(
			'x',
			$elm$json$Json$Encode$int(x)),
			_Utils_Tuple2(
			'y',
			$elm$json$Json$Encode$int(y))
		]);
};
var $author$project$GameSync$encodeRoom = function (r) {
	return _List_fromArray(
		[
			_Utils_Tuple2(
			'ref',
			$elm$json$Json$Encode$string(
				A2(
					$elm$core$Maybe$withDefault,
					'',
					$author$project$BoardMapTile$refToString(r.bJ)))),
			_Utils_Tuple2(
			'origin',
			$elm$json$Json$Encode$object(
				$author$project$SharedSync$encodeCoords(r.dj))),
			_Utils_Tuple2(
			'turns',
			$elm$json$Json$Encode$int(r.dL))
		]);
};
var $author$project$AppStorage$encodeExtendedRoomData = function (roomData) {
	return A2(
		$elm$core$List$map,
		function (r) {
			return _List_fromArray(
				[
					_Utils_Tuple2(
					'data',
					$elm$json$Json$Encode$object(
						$author$project$GameSync$encodeRoom(r.a$))),
					_Utils_Tuple2(
					'rotationPoint',
					$elm$json$Json$Encode$object(
						$author$project$SharedSync$encodeCoords(r.bU)))
				]);
		},
		roomData);
};
var $author$project$AppStorage$encodeMapData = function (data) {
	return $elm$json$Json$Encode$object(
		_List_fromArray(
			[
				_Utils_Tuple2(
				'scenarioTitle',
				$elm$json$Json$Encode$string(data.bZ)),
				_Utils_Tuple2(
				'roomData',
				A2(
					$elm$json$Json$Encode$list,
					$elm$json$Json$Encode$object,
					$author$project$AppStorage$encodeExtendedRoomData(data.bT))),
				_Utils_Tuple2(
				'overlays',
				A2(
					$elm$json$Json$Encode$list,
					$elm$json$Json$Encode$object,
					$author$project$SharedSync$encodeOverlays(data.bA))),
				_Utils_Tuple2(
				'monsters',
				A2(
					$elm$json$Json$Encode$list,
					$elm$json$Json$Encode$object,
					$author$project$SharedSync$encodeMonsters(data.bn)))
			]));
};
var $author$project$AppStorage$saveMapData = _Platform_outgoingPort('saveMapData', $elm$core$Basics$identity);
var $author$project$AppStorage$saveMapToStorage = function (map) {
	return $author$project$AppStorage$saveMapData(
		$author$project$AppStorage$encodeMapData(map));
};
var $mpizenberg$elm_pointer_events$Html$Events$Extra$Drag$effectAllowedToString = function (eff) {
	var _v0 = _Utils_Tuple3(eff.bp, eff.aZ, eff.bk);
	if (!_v0.a) {
		if (!_v0.b) {
			if (!_v0.c) {
				return 'none';
			} else {
				return 'link';
			}
		} else {
			if (!_v0.c) {
				return 'copy';
			} else {
				return 'copyLink';
			}
		}
	} else {
		if (!_v0.b) {
			if (!_v0.c) {
				return 'move';
			} else {
				return 'linkMove';
			}
		} else {
			if (!_v0.c) {
				return 'copyMove';
			} else {
				return 'all';
			}
		}
	}
};
var $mpizenberg$elm_pointer_events$Html$Events$Extra$Drag$startPortData = F2(
	function (effectAllowed, value) {
		return {
			cG: $mpizenberg$elm_pointer_events$Html$Events$Extra$Drag$effectAllowedToString(effectAllowed),
			a6: value
		};
	});
var $elm$file$File$Download$string = F3(
	function (name, mime, content) {
		return A2(
			$elm$core$Task$perform,
			$elm$core$Basics$never,
			A3(_File_download, name, mime, content));
	});
var $elm$file$File$toString = _File_toString;
var $author$project$Creator$update = F2(
	function (msg, model) {
		update:
		while (true) {
			switch (msg.$) {
				case 0:
					var piece = msg.a;
					var maybeDragData = msg.b;
					var cmd = function () {
						if (!maybeDragData.$) {
							var _v2 = maybeDragData.a;
							var e = _v2.a;
							var v = _v2.b;
							return $author$project$DragPorts$dragstart(
								A2($mpizenberg$elm_pointer_events$Html$Events$Extra$Drag$startPortData, e, v));
						} else {
							return $elm$core$Platform$Cmd$none;
						}
					}();
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{
								J: 1,
								a_: $elm$core$Maybe$Just(piece)
							}),
						cmd);
				case 1:
					var coords = msg.a;
					var maybeDragOver = msg.b;
					var _v3 = model.a_;
					if (!_v3.$) {
						var m = _v3.a;
						if (_Utils_eq(
							m.b9,
							$elm$core$Maybe$Just(coords))) {
							return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
						} else {
							var newDraggable = function () {
								var _v6 = m.bJ;
								switch (_v6.$) {
									case 0:
										var o = _v6.a;
										var prevCoords = _v6.b;
										var _v7 = A5($author$project$Game$moveOverlayWithoutState, o, m.aY, prevCoords, coords, model.a.bA);
										var newOverlay = _v7.b;
										var newCoords = _v7.c;
										var moveablePieceType = A2($author$project$AppStorage$OverlayType, newOverlay, newCoords);
										var newTarget = _Utils_eq(moveablePieceType, m.bJ) ? m.b9 : $elm$core$Maybe$Just(coords);
										return $elm$core$Maybe$Just(
											A3($author$project$AppStorage$MoveablePiece, moveablePieceType, m.aY, newTarget));
									case 1:
										var p = _v6.a;
										var pieces = A2(
											$elm$core$List$map,
											function (m1) {
												return A3(
													$author$project$Game$Piece,
													$author$project$Game$AI(
														$author$project$Game$Enemy(m1.m)),
													m1.be,
													m1.bf);
											},
											model.a.bn);
										var newPiece = $author$project$AppStorage$PieceType(
											A4($author$project$Game$movePieceWithoutState, p, m.aY, coords, pieces).b);
										var newTarget = _Utils_eq(newPiece, m.bJ) ? m.b9 : $elm$core$Maybe$Just(coords);
										return $elm$core$Maybe$Just(
											A3($author$project$AppStorage$MoveablePiece, newPiece, m.aY, newTarget));
									default:
										var r = _v6.a;
										return $elm$core$Maybe$Just(
											A3(
												$author$project$AppStorage$MoveablePiece,
												$author$project$AppStorage$RoomType(r),
												m.aY,
												$elm$core$Maybe$Just(coords)));
								}
							}();
							var cmd = function () {
								if (!maybeDragOver.$) {
									var _v5 = maybeDragOver.a;
									var e = _v5.a;
									var v = _v5.b;
									return $author$project$DragPorts$dragover(
										A2($mpizenberg$elm_pointer_events$Html$Events$Extra$Drag$overPortData, e, v));
								} else {
									return $elm$core$Platform$Cmd$none;
								}
							}();
							return _Utils_Tuple2(
								_Utils_update(
									model,
									{a_: newDraggable}),
								cmd);
						}
					} else {
						return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
					}
				case 2:
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{a_: $elm$core$Maybe$Nothing}),
						$elm$core$Platform$Cmd$none);
				case 3:
					var moveData = function () {
						var _v8 = model.a_;
						if (!_v8.$) {
							var m = _v8.a;
							var _v9 = _Utils_Tuple2(m.bJ, m.b9);
							if (!_v9.b.$) {
								switch (_v9.a.$) {
									case 0:
										var _v10 = _v9.a;
										var o = _v10.a;
										var prevCoords = _v10.b;
										var coords = _v9.b.a;
										var _v11 = A5($author$project$Game$moveOverlayWithoutState, o, m.aY, prevCoords, coords, model.a.bA);
										var g = _v11.a;
										var newOverlay = _v11.b;
										return {
											c: model.c,
											bn: model.a.bn,
											bA: A2($elm$core$List$cons, newOverlay, g),
											bT: model.a.bT
										};
									case 1:
										var p = _v9.a.a;
										var target = _v9.b.a;
										var _v12 = p.bJ;
										if ((_v12.$ === 2) && (!_v12.a.$)) {
											var pieces = A2(
												$elm$core$List$map,
												function (m1) {
													return A3(
														$author$project$Game$Piece,
														$author$project$Game$AI(
															$author$project$Game$Enemy(m1.m)),
														m1.be,
														m1.bf);
												},
												model.a.bn);
											var _v13 = A4($author$project$Game$movePieceWithoutState, p, m.aY, target, pieces);
											var newPieces = _v13.a;
											var newPiece = _v13.b;
											var m2 = A2(
												$elm$core$List$filterMap,
												A4($author$project$Creator$mapPieceToScenarioMonster, newPiece, model.a.bn, m.aY, target),
												newPieces);
											return {c: model.c, bn: m2, bA: model.a.bA, bT: model.a.bT};
										} else {
											return {c: model.c, bn: model.a.bn, bA: model.a.bA, bT: model.a.bT};
										}
									default:
										var r = _v9.a.a;
										var target = _v9.b.a;
										var room = A2(
											$elm$core$Maybe$withDefault,
											$author$project$Creator$defaultExtendedRoomData(r.bJ),
											$elm$core$List$head(
												A2(
													$elm$core$List$filter,
													function (d) {
														return _Utils_eq(d.a$.bJ, r.bJ);
													},
													model.a.bT)));
										var _v14 = A2($author$project$Creator$moveRoom, target, room);
										var cells = _v14.a;
										var newRoom = _v14.b;
										var roomList = A2(
											$elm$core$List$cons,
											newRoom,
											A2(
												$elm$core$List$filter,
												function (d) {
													return !_Utils_eq(d.a$.bJ, r.bJ);
												},
												model.a.bT));
										return {
											c: A2(
												$elm$core$List$cons,
												cells,
												A2(
													$elm$core$List$filter,
													function (_v15) {
														var ref = _v15.a;
														return !_Utils_eq(ref, r.bJ);
													},
													model.c)),
											bn: model.a.bn,
											bA: model.a.bA,
											bT: roomList
										};
								}
							} else {
								var _v16 = _v9.b;
								return {c: model.c, bn: model.a.bn, bA: model.a.bA, bT: model.a.bT};
							}
						} else {
							return {c: model.c, bn: model.a.bn, bA: model.a.bA, bT: model.a.bT};
						}
					}();
					var map = model.a;
					var newMap = _Utils_update(
						map,
						{bn: moveData.bn, bA: moveData.bA, bT: moveData.bT});
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{c: moveData.c, a_: $elm$core$Maybe$Nothing, a: newMap}),
						$author$project$AppStorage$saveMapToStorage(newMap));
				case 4:
					var piece = msg.a;
					var $temp$msg = A2($author$project$Creator$MoveStarted, piece, $elm$core$Maybe$Nothing),
						$temp$model = model;
					msg = $temp$msg;
					model = $temp$model;
					continue update;
				case 6:
					var $temp$msg = $author$project$Creator$MoveCanceled,
						$temp$model = model;
					msg = $temp$msg;
					model = $temp$model;
					continue update;
				case 5:
					var _v17 = msg.a;
					var x = _v17.a;
					var y = _v17.b;
					return _Utils_Tuple2(
						model,
						$author$project$Creator$getCellFromPoint(
							_Utils_Tuple3(x, y, false)));
				case 7:
					var _v18 = msg.a;
					var x = _v18.a;
					var y = _v18.b;
					return _Utils_Tuple2(
						model,
						$author$project$Creator$getCellFromPoint(
							_Utils_Tuple3(x, y, true)));
				case 8:
					var _v19 = msg.a;
					var x = _v19.a;
					var y = _v19.b;
					var endTouch = _v19.c;
					if (endTouch) {
						var _v20 = model.a_;
						if (!_v20.$) {
							var c = _v20.a;
							if (_Utils_eq(
								$elm$core$Maybe$Just(
									_Utils_Tuple2(x, y)),
								c.aY)) {
								var $temp$msg = $author$project$Creator$OpenContextMenu(
									_Utils_Tuple2(x, y)),
									$temp$model = _Utils_update(
									model,
									{a_: $elm$core$Maybe$Nothing});
								msg = $temp$msg;
								model = $temp$model;
								continue update;
							} else {
								var $temp$msg = $author$project$Creator$MoveCompleted,
									$temp$model = model;
								msg = $temp$msg;
								model = $temp$model;
								continue update;
							}
						} else {
							return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
						}
					} else {
						var $temp$msg = A2(
							$author$project$Creator$MoveTargetChanged,
							_Utils_Tuple2(x, y),
							$elm$core$Maybe$Nothing),
							$temp$model = model;
						msg = $temp$msg;
						model = $temp$model;
						continue update;
					}
				case 9:
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{M: !model.M}),
						$elm$core$Platform$Cmd$none);
				case 10:
					var menu = msg.a;
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{C: menu}),
						$elm$core$Platform$Cmd$none);
				case 11:
					var pos = msg.a;
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{au: pos, J: 0}),
						$author$project$Creator$getContextPosition(pos));
				case 12:
					var state = msg.a;
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{J: state}),
						$elm$core$Platform$Cmd$none);
				case 14:
					var pos = msg.a;
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{at: pos}),
						$elm$core$Platform$Cmd$none);
				case 13:
					var id = msg.a;
					var playerSize = msg.b;
					var level = msg.c;
					var monster = $elm$core$List$head(
						A2(
							$elm$core$List$filter,
							function (m1) {
								return _Utils_eq(m1.m.ag, id);
							},
							model.a.bn));
					if (!monster.$) {
						var m = monster.a;
						var newMonster = (playerSize === 2) ? _Utils_update(
							m,
							{dM: level}) : ((playerSize === 3) ? _Utils_update(
							m,
							{dF: level}) : ((playerSize === 4) ? _Utils_update(
							m,
							{cP: level}) : m));
						var newMonsterList = A2(
							$elm$core$List$cons,
							newMonster,
							A2(
								$elm$core$List$filter,
								function (m1) {
									return !_Utils_eq(m1.m.ag, id);
								},
								model.a.bn));
						var map = model.a;
						var newMap = _Utils_update(
							map,
							{bn: newMonsterList});
						return _Utils_Tuple2(
							_Utils_update(
								model,
								{J: 0, a: newMap}),
							$author$project$AppStorage$saveMapToStorage(newMap));
					} else {
						return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
					}
				case 15:
					var id = msg.a;
					var map = model.a;
					var newMap = _Utils_update(
						map,
						{
							bn: A2(
								$elm$core$List$filter,
								function (m) {
									return !_Utils_eq(m.m.ag, id);
								},
								model.a.bn)
						});
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{a: newMap}),
						$author$project$AppStorage$saveMapToStorage(newMap));
				case 16:
					var id = msg.a;
					var o1 = $elm$core$List$head(
						A2(
							$elm$core$List$filter,
							function (o) {
								return _Utils_eq(o.ag, id);
							},
							model.a.bA));
					if (!o1.$) {
						var overlay = o1.a;
						var refPoint = A2(
							$elm$core$Maybe$withDefault,
							_Utils_Tuple2(0, 0),
							$elm$core$List$head(overlay.S));
						var map = model.a;
						var cells = A2(
							$elm$core$List$map,
							function (c) {
								return A3($author$project$Hexagon$rotate, c, refPoint, 1);
							},
							overlay.S);
						var direction = function () {
							var _v23 = overlay.aw;
							switch (_v23) {
								case 0:
									return 4;
								case 4:
									return ($elm$core$List$length(cells) === 1) ? 2 : 5;
								case 2:
									return 5;
								case 5:
									return 1;
								case 1:
									return 6;
								case 6:
									return ($elm$core$List$length(cells) === 1) ? 3 : 7;
								case 3:
									return 7;
								default:
									return 0;
							}
						}();
						var newOverlay = _Utils_update(
							overlay,
							{S: cells, aw: direction});
						var overlayList = A2(
							$elm$core$List$cons,
							newOverlay,
							A2(
								$elm$core$List$filter,
								function (o2) {
									return !_Utils_eq(o2.ag, id);
								},
								model.a.bA));
						var newMap = _Utils_update(
							map,
							{bA: overlayList});
						return _Utils_Tuple2(
							_Utils_update(
								model,
								{a: newMap}),
							$author$project$AppStorage$saveMapToStorage(newMap));
					} else {
						return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
					}
				case 17:
					var id = msg.a;
					var map = model.a;
					var newMap = _Utils_update(
						map,
						{
							bA: A2(
								$elm$core$List$filter,
								function (o) {
									return !_Utils_eq(o.ag, id);
								},
								model.a.bA)
						});
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{a: newMap}),
						$author$project$AppStorage$saveMapToStorage(newMap));
				case 18:
					var ref = msg.a;
					var r = $elm$core$List$head(
						A2(
							$elm$core$List$filter,
							function (r1) {
								return _Utils_eq(r1.a$.bJ, ref);
							},
							model.a.bT));
					if (!r.$) {
						var room = r.a;
						var map = model.a;
						var _v25 = A2($author$project$Creator$rotateRoom, 1, room);
						var cells = _v25.a;
						var newRoom = _v25.b;
						var cachedRoomCells = A2(
							$elm$core$List$cons,
							cells,
							A2(
								$elm$core$List$filter,
								function (_v26) {
									var r3 = _v26.a;
									return !_Utils_eq(ref, r3);
								},
								model.c));
						var newRooms = A2(
							$elm$core$List$cons,
							newRoom,
							A2(
								$elm$core$List$filter,
								function (r2) {
									return !_Utils_eq(ref, r2.a$.bJ);
								},
								model.a.bT));
						var newMap = _Utils_update(
							map,
							{bT: newRooms});
						return _Utils_Tuple2(
							_Utils_update(
								model,
								{c: cachedRoomCells, a: newMap}),
							$author$project$AppStorage$saveMapToStorage(newMap));
					} else {
						return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
					}
				case 19:
					var ref = msg.a;
					var map = model.a;
					var newMap = _Utils_update(
						map,
						{
							bT: A2(
								$elm$core$List$filter,
								function (r) {
									return !_Utils_eq(r.a$.bJ, ref);
								},
								model.a.bT)
						});
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{
								c: A2(
									$elm$core$List$filter,
									function (_v27) {
										var r = _v27.a;
										return !_Utils_eq(r, ref);
									},
									model.c),
								a: newMap
							}),
						$author$project$AppStorage$saveMapToStorage(newMap));
				case 20:
					return _Utils_Tuple2(
						model,
						$author$project$Creator$getConfirmCreateNew(0));
				case 21:
					var mapData = A4($author$project$AppStorage$MapData, '', _List_Nil, _List_Nil, _List_Nil);
					return _Utils_Tuple2(
						$author$project$Creator$initModel(mapData),
						$author$project$AppStorage$saveMapToStorage(mapData));
				case 22:
					var roomData = A2(
						$elm$core$List$map,
						function (r) {
							return r.a$;
						},
						model.a.bT);
					var overlays = A2(
						$elm$core$List$filterMap,
						function (o) {
							return function (e) {
								if ((!e.$) && (!e.a.$)) {
									var a = e.a.a;
									return $elm$core$Maybe$Just(a);
								} else {
									return $elm$core$Maybe$Nothing;
								}
							}(
								A2(
									$elm$core$Maybe$map,
									function (origin) {
										var _v31 = origin;
										var x = _v31.a;
										var y = _v31.b;
										var startY = y + 1;
										var cells = A2(
											$elm$core$List$cons,
											origin,
											A2(
												$elm$core$List$map,
												function (i) {
													return A3(
														$author$project$Hexagon$rotate,
														_Utils_Tuple2(x, startY),
														origin,
														i);
												},
												A2($elm$core$List$range, 1, 6)));
										var rooms = A2(
											$elm$core$List$filterMap,
											function (c) {
												return $elm$core$List$head(
													A2(
														$elm$core$List$filterMap,
														function (r) {
															return A2($elm$core$Dict$member, c, r.b) ? $elm$core$Maybe$Just(r.a) : $elm$core$Maybe$Nothing;
														},
														model.c));
											},
											cells);
										var _v32 = $elm$core$List$head(rooms);
										if (!_v32.$) {
											var c = _v32.a;
											var _v33 = o.bJ;
											if (_v33.$ === 1) {
												var d = _v33.a;
												var distinctRoom = A3(
													$elm$core$List$foldr,
													F2(
														function (a, b) {
															return A2($elm$core$List$member, a, b) ? b : A2($elm$core$List$cons, a, b);
														}),
													_List_Nil,
													rooms);
												return $elm$core$Maybe$Just(
													_Utils_Tuple2(
														c,
														_Utils_update(
															o,
															{
																bJ: A2($author$project$BoardOverlay$Door, d, distinctRoom)
															})));
											} else {
												return A2(
													$elm$core$Maybe$map,
													function (m) {
														var newCells = A2(
															$elm$core$List$filterMap,
															function (cell) {
																return A4($author$project$Creator$mapCoordsToRoom, m.a$.bJ, m.a$.dL, cell, model.c);
															},
															o.S);
														return _Utils_Tuple2(
															c,
															_Utils_update(
																o,
																{S: newCells}));
													},
													$elm$core$List$head(
														A2(
															$elm$core$List$filter,
															function (m) {
																return _Utils_eq(m.a$.bJ, c);
															},
															model.a.bT)));
											}
										} else {
											return $elm$core$Maybe$Nothing;
										}
									},
									$elm$core$List$head(o.S)));
						},
						model.a.bA);
					var monsters = A2(
						$elm$core$List$filterMap,
						function (m) {
							var startY = m.bf + 1;
							var origin = _Utils_Tuple2(m.be, m.bf);
							var cells = A2(
								$elm$core$List$cons,
								origin,
								A2(
									$elm$core$List$map,
									function (i) {
										return A3(
											$author$project$Hexagon$rotate,
											_Utils_Tuple2(m.be, startY),
											origin,
											i);
									},
									A2($elm$core$List$range, 1, 6)));
							var room = $elm$core$List$head(
								A2(
									$elm$core$List$filterMap,
									function (c) {
										return $elm$core$List$head(
											A2(
												$elm$core$List$filterMap,
												function (r) {
													return A2($elm$core$Dict$member, c, r.b) ? $elm$core$Maybe$Just(r.a) : $elm$core$Maybe$Nothing;
												},
												model.c));
									},
									cells));
							return A2(
								$elm$core$Maybe$andThen,
								function (_v29) {
									var r = _v29.a;
									return A2(
										$elm$core$Maybe$map,
										function (_v30) {
											var newX = _v30.a;
											var newY = _v30.b;
											return _Utils_Tuple2(
												r,
												_Utils_update(
													m,
													{be: newX, bf: newY}));
										},
										A2(
											$elm$core$Maybe$andThen,
											function (m2) {
												return A4(
													$author$project$Creator$mapCoordsToRoom,
													m2.a$.bJ,
													m2.a$.dL,
													_Utils_Tuple2(m.be, m.bf),
													model.c);
											},
											$elm$core$List$head(
												A2(
													$elm$core$List$filter,
													function (m2) {
														return _Utils_eq(m2.a$.bJ, r);
													},
													model.a.bT))));
								},
								A2(
									$elm$core$Maybe$map,
									function (r) {
										return _Utils_Tuple2(r, m);
									},
									room));
						},
						model.a.bn);
					var scenario = A5($author$project$Creator$generateScenario, model.a.bZ, roomData, overlays, monsters, model.c);
					if (!scenario.$) {
						var s = scenario.a;
						return _Utils_Tuple2(
							model,
							A3(
								$elm$file$File$Download$string,
								model.a.bZ + '.json',
								'application/json',
								A2(
									$elm$json$Json$Encode$encode,
									4,
									$author$project$ScenarioSync$encodeScenario(s))));
					} else {
						var e = scenario.a;
						return _Utils_Tuple2(
							_Utils_update(
								model,
								{af: e, X: true}),
							$elm$core$Platform$Cmd$none);
					}
				case 23:
					return _Utils_Tuple2(
						model,
						A2(
							$elm$file$File$Select$file,
							_List_fromArray(
								['application/json']),
							$author$project$Creator$ExtractFileString));
				case 24:
					var file = msg.a;
					return _Utils_Tuple2(
						model,
						A2(
							$elm$core$Task$perform,
							$author$project$Creator$LoadScenario,
							$elm$file$File$toString(file)));
				case 25:
					var str = msg.a;
					var _v35 = A2($elm$json$Json$Decode$decodeString, $author$project$ScenarioSync$decodeScenario, str);
					if (!_v35.$) {
						var scenario = _v35.a;
						var map = model.a;
						var _v36 = function (g) {
							return _Utils_Tuple3(
								g.bT,
								g.ap.bA,
								A2(
									$elm$core$List$filterMap,
									function (m) {
										var _v37 = m.bJ;
										if ((_v37.$ === 2) && (!_v37.a.$)) {
											var monster = _v37.a.a;
											return $elm$core$Maybe$Just(
												A6($author$project$Scenario$ScenarioMonster, monster, m.ci, m.cj, monster.bj, 0, 0));
										} else {
											return $elm$core$Maybe$Nothing;
										}
									},
									g.ap.bD));
						}(
							A5(
								$author$project$Game$generateGameMap,
								$author$project$Game$CustomScenario(str),
								scenario,
								'',
								_List_fromArray(
									[3, 4]),
								$elm$random$Random$initialSeed(0)));
						var rooms = _v36.a;
						var initOverlays = _v36.b;
						var twoPlayerMonsters = _v36.c;
						var threePlayerMonsters = A3(
							$elm$core$List$foldr,
							F2(
								function (monster, currentMonsters) {
									var m = $elm$core$List$head(
										A2(
											$elm$core$List$filter,
											function (m3) {
												return _Utils_eq(m3.be, monster.be) && _Utils_eq(m3.bf, monster.bf);
											},
											currentMonsters));
									if (!m.$) {
										var m1 = m.a;
										return A2(
											$elm$core$List$cons,
											_Utils_update(
												m1,
												{dF: monster.dF}),
											A2(
												$elm$core$List$filter,
												function (m2) {
													return !_Utils_eq(m2, m1);
												},
												currentMonsters));
									} else {
										return A2($elm$core$List$cons, monster, currentMonsters);
									}
								}),
							twoPlayerMonsters,
							function (g) {
								return A2(
									$elm$core$List$filterMap,
									function (m) {
										var _v48 = m.bJ;
										if ((_v48.$ === 2) && (!_v48.a.$)) {
											var monster = _v48.a.a;
											return $elm$core$Maybe$Just(
												A6($author$project$Scenario$ScenarioMonster, monster, m.ci, m.cj, 0, monster.bj, 0));
										} else {
											return $elm$core$Maybe$Nothing;
										}
									},
									g.ap.bD);
							}(
								A5(
									$author$project$Game$generateGameMap,
									$author$project$Game$CustomScenario(str),
									scenario,
									'',
									_List_fromArray(
										[3, 4, 15]),
									$elm$random$Random$initialSeed(0))));
						var _v38 = A3(
							$elm$core$List$foldr,
							F2(
								function (_v40, _v41) {
									var c = _v40.a;
									var r = _v40.b;
									var cells1 = _v41.a;
									var rooms1 = _v41.b;
									return _Utils_Tuple2(
										A2($elm$core$List$cons, c, cells1),
										A2($elm$core$List$cons, r, rooms1));
								}),
							_Utils_Tuple2(_List_Nil, _List_Nil),
							A2(
								$elm$core$List$map,
								function (r) {
									return function (_v39) {
										var r1 = _v39.b;
										return A2($author$project$Creator$moveRoom, r.dj, r1);
									}(
										A2(
											$author$project$Creator$rotateRoom,
											r.dL,
											$author$project$Creator$defaultExtendedRoomData(r.bJ)));
								},
								rooms));
						var cells = _v38.a;
						var roomData = _v38.b;
						var _v42 = A3(
							$elm$core$List$foldr,
							F2(
								function (a, _v43) {
									var i = _v43.a;
									var b = _v43.b;
									return _Utils_Tuple2(
										i + 1,
										A2(
											$elm$core$List$cons,
											_Utils_update(
												a,
												{ag: i}),
											b));
								}),
							_Utils_Tuple2(1, _List_Nil),
							initOverlays);
						var overlays = _v42.b;
						var _v44 = A3(
							$elm$core$List$foldr,
							F2(
								function (a, _v47) {
									var i = _v47.a;
									var b = _v47.b;
									var m = a.m;
									return _Utils_Tuple2(
										i + 1,
										A2(
											$elm$core$List$cons,
											_Utils_update(
												a,
												{
													m: _Utils_update(
														m,
														{ag: i})
												}),
											b));
								}),
							_Utils_Tuple2(1, _List_Nil),
							A3(
								$elm$core$List$foldr,
								F2(
									function (monster, currentMonsters) {
										var m = $elm$core$List$head(
											A2(
												$elm$core$List$filter,
												function (m3) {
													return _Utils_eq(m3.be, monster.be) && _Utils_eq(m3.bf, monster.bf);
												},
												currentMonsters));
										if (!m.$) {
											var m1 = m.a;
											return A2(
												$elm$core$List$cons,
												_Utils_update(
													m1,
													{cP: monster.cP}),
												A2(
													$elm$core$List$filter,
													function (m2) {
														return !_Utils_eq(m2, m1);
													},
													currentMonsters));
										} else {
											return A2($elm$core$List$cons, monster, currentMonsters);
										}
									}),
								threePlayerMonsters,
								function (g) {
									return A2(
										$elm$core$List$filterMap,
										function (m) {
											var _v45 = m.bJ;
											if ((_v45.$ === 2) && (!_v45.a.$)) {
												var monster = _v45.a.a;
												return $elm$core$Maybe$Just(
													A6($author$project$Scenario$ScenarioMonster, monster, m.ci, m.cj, 0, 0, monster.bj));
											} else {
												return $elm$core$Maybe$Nothing;
											}
										},
										g.ap.bD);
								}(
									A5(
										$author$project$Game$generateGameMap,
										$author$project$Game$CustomScenario(str),
										scenario,
										'',
										_List_fromArray(
											[3, 4, 15, 18]),
										$elm$random$Random$initialSeed(0)))));
						var monsters = _v44.b;
						var newMap = _Utils_update(
							map,
							{bn: monsters, bA: overlays, bT: roomData, bZ: scenario.dJ});
						return _Utils_Tuple2(
							_Utils_update(
								model,
								{c: cells, a: newMap}),
							$author$project$AppStorage$saveMapToStorage(newMap));
					} else {
						var e = _v35.a;
						return _Utils_Tuple2(
							_Utils_update(
								model,
								{
									af: $elm$json$Json$Decode$errorToString(e),
									X: true
								}),
							$elm$core$Platform$Cmd$none);
					}
				case 26:
					var title = msg.a;
					var map = model.a;
					var newMap = _Utils_update(
						map,
						{bZ: title});
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{a: newMap}),
						$author$project$AppStorage$saveMapToStorage(newMap));
				case 27:
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{X: false}),
						$elm$core$Platform$Cmd$none);
				default:
					return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
			}
		}
	});
var $elm$json$Json$Decode$value = _Json_decodeValue;
var $author$project$Creator$BossMenu = 5;
var $author$project$Creator$ChangeContextMenuState = function (a) {
	return {$: 12, a: a};
};
var $author$project$Creator$DoorMenu = 1;
var $author$project$Creator$MiscMenu = 3;
var $author$project$Creator$MonsterMenu = 4;
var $author$project$Creator$ObstacleMenu = 2;
var $author$project$Creator$TouchCanceled = {$: 6};
var $elm$html$Html$Attributes$stringProperty = F2(
	function (key, string) {
		return A2(
			_VirtualDom_property,
			key,
			$elm$json$Json$Encode$string(string));
	});
var $elm$html$Html$Attributes$class = $elm$html$Html$Attributes$stringProperty('className');
var $elm$html$Html$div = _VirtualDom_node('div');
var $author$project$Character$BeastTyrant = 0;
var $author$project$Character$Berserker = 1;
var $author$project$Character$Bladeswarm = 2;
var $author$project$Character$Diviner = 5;
var $author$project$Character$Doomstalker = 6;
var $author$project$Character$Elementalist = 7;
var $author$project$Character$Mindthief = 8;
var $author$project$Character$Nightshroud = 9;
var $author$project$Character$PlagueHerald = 10;
var $author$project$Character$Quartermaster = 11;
var $author$project$Character$Sawbones = 12;
var $author$project$Character$Scoundrel = 13;
var $author$project$Character$Soothsinger = 14;
var $author$project$Character$Summoner = 16;
var $author$project$Character$Sunkeeper = 17;
var $author$project$Character$characterDictionary = $elm$core$Dict$fromList(
	_List_fromArray(
		[
			_Utils_Tuple2('brute', 3),
			_Utils_Tuple2('tinkerer', 18),
			_Utils_Tuple2('scoundrel', 13),
			_Utils_Tuple2('cragheart', 4),
			_Utils_Tuple2('mindthief', 8),
			_Utils_Tuple2('spellweaver', 15),
			_Utils_Tuple2('diviner', 5),
			_Utils_Tuple2('phoenix-face', 0),
			_Utils_Tuple2('lightning-bolt', 1),
			_Utils_Tuple2('angry-face', 6),
			_Utils_Tuple2('triforce', 7),
			_Utils_Tuple2('eclipse', 9),
			_Utils_Tuple2('cthulhu', 10),
			_Utils_Tuple2('three-spears', 11),
			_Utils_Tuple2('saw', 12),
			_Utils_Tuple2('music-note', 14),
			_Utils_Tuple2('concentric-circles', 16),
			_Utils_Tuple2('sun', 17),
			_Utils_Tuple2('envelope-x', 2)
		]));
var $author$project$Character$characterToString = function (character) {
	var maybeKey = $elm$core$List$head(
		$elm$core$Dict$toList(
			A2(
				$elm$core$Dict$filter,
				F2(
					function (_v1, v) {
						return _Utils_eq(v, character);
					}),
				$author$project$Character$characterDictionary)));
	return A2(
		$elm$core$Maybe$map,
		function (_v0) {
			var k = _v0.a;
			return k;
		},
		maybeKey);
};
var $author$project$GameSync$encodeMonsterLevel = function (level) {
	switch (level) {
		case 1:
			return 'normal';
		case 2:
			return 'elite';
		default:
			return 'none';
	}
};
var $author$project$GameSync$encodeSummons = function (summons) {
	var fields = function () {
		if (!summons.$) {
			var i = summons.a;
			var colour = summons.b;
			return _List_fromArray(
				[
					_Utils_Tuple2(
					'id',
					$elm$json$Json$Encode$int(i)),
					_Utils_Tuple2(
					'colour',
					$elm$json$Json$Encode$string(
						$author$project$Colour$toHexString(colour)))
				]);
		} else {
			return _List_fromArray(
				[
					_Utils_Tuple2(
					'id',
					$elm$json$Json$Encode$string('bear'))
				]);
		}
	}();
	return A2(
		$elm$core$List$cons,
		_Utils_Tuple2(
			'type',
			$elm$json$Json$Encode$string('summons')),
		fields);
};
var $author$project$GameSync$encodePieceType = function (pieceType) {
	switch (pieceType.$) {
		case 0:
			return _List_Nil;
		case 1:
			var p = pieceType.a;
			return _List_fromArray(
				[
					_Utils_Tuple2(
					'type',
					$elm$json$Json$Encode$string('player')),
					_Utils_Tuple2(
					'class',
					$elm$json$Json$Encode$string(
						A2(
							$elm$core$Maybe$withDefault,
							'',
							$author$project$Character$characterToString(p))))
				]);
		default:
			if (pieceType.a.$ === 1) {
				var t = pieceType.a.a;
				return $author$project$GameSync$encodeSummons(t);
			} else {
				var monster = pieceType.a.a;
				return _List_fromArray(
					[
						_Utils_Tuple2(
						'type',
						$elm$json$Json$Encode$string('monster')),
						_Utils_Tuple2(
						'class',
						$elm$json$Json$Encode$string(
							A2(
								$elm$core$Maybe$withDefault,
								'',
								$author$project$Monster$monsterTypeToString(monster.m)))),
						_Utils_Tuple2(
						'id',
						$elm$json$Json$Encode$int(monster.ag)),
						_Utils_Tuple2(
						'level',
						$elm$json$Json$Encode$string(
							$author$project$GameSync$encodeMonsterLevel(monster.bj))),
						_Utils_Tuple2(
						'wasSummoned',
						$elm$json$Json$Encode$bool(monster.cg)),
						_Utils_Tuple2(
						'outOfPhase',
						$elm$json$Json$Encode$bool(monster.bz))
					]);
			}
	}
};
var $author$project$GameSync$encodePiece = function (p) {
	return _List_fromArray(
		[
			_Utils_Tuple2(
			'ref',
			$elm$json$Json$Encode$object(
				$author$project$GameSync$encodePieceType(p.bJ))),
			_Utils_Tuple2(
			'x',
			$elm$json$Json$Encode$int(p.ci)),
			_Utils_Tuple2(
			'y',
			$elm$json$Json$Encode$int(p.cj))
		]);
};
var $author$project$AppStorage$encodeMoveablePieceType = function (pieceType) {
	return _Utils_ap(
		_List_fromArray(
			[
				_Utils_Tuple2(
				'type',
				$elm$json$Json$Encode$string(
					function () {
						switch (pieceType.$) {
							case 0:
								return 'overlay';
							case 1:
								return 'piece';
							default:
								return 'room';
						}
					}())),
				_Utils_Tuple2(
				'data',
				$elm$json$Json$Encode$object(
					function () {
						switch (pieceType.$) {
							case 0:
								var o = pieceType.a;
								return $author$project$SharedSync$encodeOverlay(o);
							case 1:
								var p = pieceType.a;
								return $author$project$GameSync$encodePiece(p);
							default:
								var r = pieceType.a;
								return $author$project$GameSync$encodeRoom(r);
						}
					}()))
			]),
		function () {
			switch (pieceType.$) {
				case 0:
					var c = pieceType.b;
					return _List_fromArray(
						[
							_Utils_Tuple2(
							'ref',
							function () {
								if (!c.$) {
									var v = c.a;
									return $elm$json$Json$Encode$object(
										$author$project$SharedSync$encodeCoords(v));
								} else {
									return $elm$json$Json$Encode$null;
								}
							}())
						]);
				case 1:
					return _List_Nil;
				default:
					return _List_Nil;
			}
		}());
};
var $author$project$AppStorage$encodeMoveablePiece = function (piece) {
	return $elm$json$Json$Encode$object(
		_List_fromArray(
			[
				_Utils_Tuple2(
				'ref',
				$elm$json$Json$Encode$object(
					$author$project$AppStorage$encodeMoveablePieceType(piece.bJ))),
				_Utils_Tuple2(
				'coords',
				function () {
					var _v0 = piece.aY;
					if (!_v0.$) {
						var c = _v0.a;
						return $elm$json$Json$Encode$object(
							$author$project$SharedSync$encodeCoords(c));
					} else {
						return $elm$json$Json$Encode$null;
					}
				}()),
				_Utils_Tuple2(
				'target',
				function () {
					var _v1 = piece.b9;
					if (!_v1.$) {
						var c = _v1.a;
						return $elm$json$Json$Encode$object(
							$author$project$SharedSync$encodeCoords(c));
					} else {
						return $elm$json$Json$Encode$null;
					}
				}())
			]));
};
var $author$project$Version$get = '1.14.0';
var $author$project$Creator$emptyList = _List_Nil;
var $author$project$BoardHtml$CellModel = function (overlays) {
	return function (pieces) {
		return function (scenarioMonsters) {
			return function (coords) {
				return function (currentDraggable) {
					return function (dragOverlays) {
						return function (dragPieces) {
							return function (dragDoors) {
								return function (dragEvents) {
									return function (dropEvents) {
										return function (passable) {
											return function (hidden) {
												return {aY: coords, a_: currentDraggable, ac: dragDoors, l: dragEvents, ad: dragOverlays, ae: dragPieces, a3: dropEvents, aA: hidden, bA: overlays, aG: passable, bD: pieces, bY: scenarioMonsters};
											};
										};
									};
								};
							};
						};
					};
				};
			};
		};
	};
};
var $elm$virtual_dom$VirtualDom$Custom = function (a) {
	return {$: 3, a: a};
};
var $elm$core$Basics$composeR = F3(
	function (f, g, x) {
		return g(
			f(x));
	});
var $visotype$elm_dom$Dom$Internal$Element = $elm$core$Basics$identity;
var $visotype$elm_dom$Dom$Internal$modify = F2(
	function (f, _v0) {
		var data = _v0;
		return f(data);
	});
var $visotype$elm_dom$Dom$addActionStopAndPrevent = function (_v0) {
	var event = _v0.a;
	var msg = _v0.b;
	var handler = A2(
		$elm$core$Basics$composeR,
		$elm$json$Json$Decode$succeed,
		A2(
			$elm$core$Basics$composeR,
			$elm$json$Json$Decode$map(
				function (x) {
					return {c1: x, dr: true, dA: true};
				}),
			$elm$virtual_dom$VirtualDom$Custom));
	return $visotype$elm_dom$Dom$Internal$modify(
		function (n) {
			return _Utils_update(
				n,
				{
					b: A2(
						$elm$core$List$append,
						n.b,
						_List_fromArray(
							[
								_Utils_Tuple2(
								event,
								handler(msg))
							]))
				});
		});
};
var $visotype$elm_dom$Dom$addClass = function (s) {
	return $visotype$elm_dom$Dom$Internal$modify(
		function (n) {
			return _Utils_update(
				n,
				{
					A: A2(
						$elm$core$List$append,
						n.A,
						_List_fromArray(
							[s]))
				});
		});
};
var $visotype$elm_dom$Dom$addClassConditional = F2(
	function (s, test) {
		if (test) {
			return $visotype$elm_dom$Dom$addClass(s);
		} else {
			return function (x) {
				return x;
			};
		}
	});
var $elm$virtual_dom$VirtualDom$keyedNode = function (tag) {
	return _VirtualDom_keyedNode(
		_VirtualDom_noScript(tag));
};
var $elm$virtual_dom$VirtualDom$keyedNodeNS = F2(
	function (namespace, tag) {
		return A2(
			_VirtualDom_keyedNodeNS,
			namespace,
			_VirtualDom_noScript(tag));
	});
var $elm$virtual_dom$VirtualDom$node = function (tag) {
	return _VirtualDom_node(
		_VirtualDom_noScript(tag));
};
var $elm$virtual_dom$VirtualDom$nodeNS = function (tag) {
	return _VirtualDom_nodeNS(
		_VirtualDom_noScript(tag));
};
var $elm$virtual_dom$VirtualDom$on = _VirtualDom_on;
var $elm$virtual_dom$VirtualDom$property = F2(
	function (key, value) {
		return A2(
			_VirtualDom_property,
			_VirtualDom_noInnerHtmlOrFormAction(key),
			_VirtualDom_noJavaScriptOrHtmlUri(value));
	});
var $elm$virtual_dom$VirtualDom$style = _VirtualDom_style;
var $elm$virtual_dom$VirtualDom$text = _VirtualDom_text;
var $visotype$elm_dom$Dom$Internal$render = function (_v0) {
	var data = _v0;
	var prependStyles = function () {
		var _v8 = data.b4;
		if (!_v8.b) {
			return function (x) {
				return x;
			};
		} else {
			return $elm$core$List$append(
				A2(
					$elm$core$List$map,
					function (_v9) {
						var k = _v9.a;
						var v = _v9.b;
						return A2($elm$virtual_dom$VirtualDom$style, k, v);
					},
					data.b4));
		}
	}();
	var prependListeners = function () {
		var _v6 = data.b;
		if (!_v6.b) {
			return function (x) {
				return x;
			};
		} else {
			return $elm$core$List$append(
				A2(
					$elm$core$List$map,
					function (_v7) {
						var k = _v7.a;
						var v = _v7.b;
						return A2($elm$virtual_dom$VirtualDom$on, k, v);
					},
					data.b));
		}
	}();
	var consTextKeyed = function () {
		var _v5 = data.aL;
		if (_v5 === '') {
			return function (x) {
				return x;
			};
		} else {
			return $elm$core$List$cons(
				A2(
					$elm$core$Tuple$pair,
					'rendered-internal-text',
					$elm$virtual_dom$VirtualDom$text(data.aL)));
		}
	}();
	var consText = function () {
		var _v4 = data.aL;
		if (_v4 === '') {
			return function (x) {
				return x;
			};
		} else {
			return $elm$core$List$cons(
				$elm$virtual_dom$VirtualDom$text(data.aL));
		}
	}();
	var consId = function () {
		var _v3 = data.ag;
		if (_v3 === '') {
			return function (x) {
				return x;
			};
		} else {
			return $elm$core$List$cons(
				A2(
					$elm$virtual_dom$VirtualDom$property,
					'id',
					$elm$json$Json$Encode$string(data.ag)));
		}
	}();
	var consClassName = function () {
		var _v2 = data.A;
		if (!_v2.b) {
			return function (x) {
				return x;
			};
		} else {
			return $elm$core$List$cons(
				A2(
					$elm$virtual_dom$VirtualDom$property,
					'className',
					$elm$json$Json$Encode$string(
						A2($elm$core$String$join, ' ', data.A))));
		}
	}();
	var allAttributes = consId(
		consClassName(
			prependStyles(
				prependListeners(data.I))));
	var _v1 = _Utils_Tuple2(data.c6, data.cX);
	if (_v1.a === '') {
		if (!_v1.b.b) {
			return A3(
				$elm$virtual_dom$VirtualDom$node,
				data.aK,
				allAttributes,
				consText(data.cw));
		} else {
			return A3(
				$elm$virtual_dom$VirtualDom$keyedNode,
				data.aK,
				allAttributes,
				consTextKeyed(
					A3($elm$core$List$map2, $elm$core$Tuple$pair, data.cX, data.cw)));
		}
	} else {
		if (!_v1.b.b) {
			return A4(
				$elm$virtual_dom$VirtualDom$nodeNS,
				data.c6,
				data.aK,
				allAttributes,
				consText(data.cw));
		} else {
			return A4(
				$elm$virtual_dom$VirtualDom$keyedNodeNS,
				data.c6,
				data.aK,
				allAttributes,
				consTextKeyed(
					A3($elm$core$List$map2, $elm$core$Tuple$pair, data.cX, data.cw)));
		}
	}
};
var $visotype$elm_dom$Dom$appendChild = function (e) {
	var r = $visotype$elm_dom$Dom$Internal$render(e);
	return $visotype$elm_dom$Dom$Internal$modify(
		function (n) {
			return _Utils_update(
				n,
				{
					cw: A2(
						$elm$core$List$append,
						n.cw,
						_List_fromArray(
							[r]))
				});
		});
};
var $visotype$elm_dom$Dom$appendChildConditional = F2(
	function (e, test) {
		if (test) {
			return $visotype$elm_dom$Dom$appendChild(e);
		} else {
			return function (x) {
				return x;
			};
		}
	});
var $author$project$Game$Player = function (a) {
	return {$: 1, a: a};
};
var $author$project$Character$stringToCharacter = function (character) {
	return A2(
		$elm$core$Dict$get,
		$elm$core$String$toLower(character),
		$author$project$Character$characterDictionary);
};
var $author$project$GameSync$decodeCharacter = A2(
	$elm$json$Json$Decode$andThen,
	function (c) {
		var _v0 = $author$project$Character$stringToCharacter(c);
		if (!_v0.$) {
			var _class = _v0.a;
			return $elm$json$Json$Decode$succeed(_class);
		} else {
			return $elm$json$Json$Decode$fail(c + ' is not a valid player class');
		}
	},
	A2($elm$json$Json$Decode$field, 'class', $elm$json$Json$Decode$string));
var $author$project$SharedSync$decodeMonsterType = function (m) {
	var _v0 = $author$project$Monster$stringToMonsterType(m);
	if (!_v0.$) {
		var mt = _v0.a;
		return $elm$json$Json$Decode$succeed(mt);
	} else {
		return $elm$json$Json$Decode$fail(m + ' is not a valid monster type');
	}
};
var $author$project$SharedSync$decodeMonster = A6(
	$elm$json$Json$Decode$map5,
	$author$project$Monster$Monster,
	A2(
		$elm$json$Json$Decode$andThen,
		$author$project$SharedSync$decodeMonsterType,
		A2($elm$json$Json$Decode$field, 'class', $elm$json$Json$Decode$string)),
	A2($elm$json$Json$Decode$field, 'id', $elm$json$Json$Decode$int),
	A2(
		$elm$json$Json$Decode$andThen,
		$author$project$SharedSync$decodeMonsterLevel,
		A2($elm$json$Json$Decode$field, 'level', $elm$json$Json$Decode$string)),
	A2(
		$elm$json$Json$Decode$andThen,
		function (s) {
			return $elm$json$Json$Decode$succeed(
				A2($elm$core$Maybe$withDefault, false, s));
		},
		$elm$json$Json$Decode$maybe(
			A2($elm$json$Json$Decode$field, 'wasSummoned', $elm$json$Json$Decode$bool))),
	A2(
		$elm$json$Json$Decode$andThen,
		function (s) {
			return $elm$json$Json$Decode$succeed(
				A2($elm$core$Maybe$withDefault, false, s));
		},
		$elm$json$Json$Decode$maybe(
			A2($elm$json$Json$Decode$field, 'outOfPhase', $elm$json$Json$Decode$bool))));
var $author$project$Game$BearSummons = {$: 1};
var $author$project$Game$NormalSummons = F2(
	function (a, b) {
		return {$: 0, a: a, b: b};
	});
var $author$project$Game$Summons = function (a) {
	return {$: 1, a: a};
};
var $author$project$GameSync$decodeSummons = $elm$json$Json$Decode$oneOf(
	_List_fromArray(
		[
			A2(
			$elm$json$Json$Decode$andThen,
			function (i) {
				return A2(
					$elm$json$Json$Decode$andThen,
					function (c) {
						return $elm$json$Json$Decode$succeed(
							$author$project$Game$Summons(
								A2(
									$author$project$Game$NormalSummons,
									i,
									$author$project$Colour$fromHexString(c))));
					},
					A2($elm$json$Json$Decode$field, 'colour', $elm$json$Json$Decode$string));
			},
			A2($elm$json$Json$Decode$field, 'id', $elm$json$Json$Decode$int)),
			A2(
			$elm$json$Json$Decode$andThen,
			function (s) {
				var _v0 = $elm$core$String$toLower(s);
				if (_v0 === 'bear') {
					return $elm$json$Json$Decode$succeed(
						$author$project$Game$Summons($author$project$Game$BearSummons));
				} else {
					return $elm$json$Json$Decode$fail('Cannot convert ' + (s + ' to summons type'));
				}
			},
			A2($elm$json$Json$Decode$field, 'id', $elm$json$Json$Decode$string))
		]));
var $author$project$GameSync$decodePieceType = function () {
	var decodeType = function (typeName) {
		var _v0 = $elm$core$String$toLower(typeName);
		switch (_v0) {
			case 'player':
				return A2(
					$elm$json$Json$Decode$andThen,
					function (c) {
						return $elm$json$Json$Decode$succeed(
							$author$project$Game$Player(c));
					},
					$author$project$GameSync$decodeCharacter);
			case 'monster':
				return A2(
					$elm$json$Json$Decode$andThen,
					function (m) {
						return $elm$json$Json$Decode$succeed(
							$author$project$Game$AI(
								$author$project$Game$Enemy(m)));
					},
					$author$project$SharedSync$decodeMonster);
			case 'summons':
				return A2(
					$elm$json$Json$Decode$andThen,
					function (c) {
						return $elm$json$Json$Decode$succeed(
							$author$project$Game$AI(c));
					},
					$author$project$GameSync$decodeSummons);
			default:
				return $elm$json$Json$Decode$fail('Unknown overlay type: ' + typeName);
		}
	};
	return A2(
		$elm$json$Json$Decode$andThen,
		decodeType,
		A2($elm$json$Json$Decode$field, 'type', $elm$json$Json$Decode$string));
}();
var $author$project$GameSync$decodePiece = A4(
	$elm$json$Json$Decode$map3,
	$author$project$Game$Piece,
	A2($elm$json$Json$Decode$field, 'ref', $author$project$GameSync$decodePieceType),
	A2($elm$json$Json$Decode$field, 'x', $elm$json$Json$Decode$int),
	A2($elm$json$Json$Decode$field, 'y', $elm$json$Json$Decode$int));
var $elm$json$Json$Decode$nullable = function (decoder) {
	return $elm$json$Json$Decode$oneOf(
		_List_fromArray(
			[
				$elm$json$Json$Decode$null($elm$core$Maybe$Nothing),
				A2($elm$json$Json$Decode$map, $elm$core$Maybe$Just, decoder)
			]));
};
var $author$project$AppStorage$decodeMoveablePieceType = A2(
	$elm$json$Json$Decode$andThen,
	function (s) {
		var _v0 = $elm$core$String$toLower(s);
		switch (_v0) {
			case 'overlay':
				return A2(
					$elm$json$Json$Decode$andThen,
					function (o) {
						return A2(
							$elm$json$Json$Decode$andThen,
							function (c) {
								return $elm$json$Json$Decode$succeed(
									A2($author$project$AppStorage$OverlayType, o, c));
							},
							A2(
								$elm$json$Json$Decode$field,
								'ref',
								$elm$json$Json$Decode$nullable($author$project$SharedSync$decodeCoords)));
					},
					A2($elm$json$Json$Decode$field, 'data', $author$project$SharedSync$decodeBoardOverlay));
			case 'piece':
				return A2(
					$elm$json$Json$Decode$andThen,
					function (p) {
						return $elm$json$Json$Decode$succeed(
							$author$project$AppStorage$PieceType(p));
					},
					A2($elm$json$Json$Decode$field, 'data', $author$project$GameSync$decodePiece));
			case 'room':
				return A2(
					$elm$json$Json$Decode$andThen,
					function (r) {
						return $elm$json$Json$Decode$succeed(
							$author$project$AppStorage$RoomType(r));
					},
					A2($elm$json$Json$Decode$field, 'data', $author$project$GameSync$decodeRoom));
			default:
				return $elm$json$Json$Decode$fail('Cannot decode ' + (s + ' as moveable piece'));
		}
	},
	A2($elm$json$Json$Decode$field, 'type', $elm$json$Json$Decode$string));
var $author$project$AppStorage$decodeMoveablePiece = A4(
	$elm$json$Json$Decode$map3,
	$author$project$AppStorage$MoveablePiece,
	A2($elm$json$Json$Decode$field, 'ref', $author$project$AppStorage$decodeMoveablePieceType),
	A2(
		$elm$json$Json$Decode$field,
		'coords',
		$elm$json$Json$Decode$nullable($author$project$SharedSync$decodeCoords)),
	A2(
		$elm$json$Json$Decode$field,
		'target',
		$elm$json$Json$Decode$nullable($author$project$SharedSync$decodeCoords)));
var $author$project$BoardHtml$DragEvents = F6(
	function (moveStart, moveCancel, touchStart, touchMove, touchEnd, noOp) {
		return {bq: moveCancel, bs: moveStart, aE: noOp, ca: touchEnd, cb: touchMove, cc: touchStart};
	});
var $author$project$Creator$NoOp = {$: 28};
var $author$project$Creator$TouchEnd = function (a) {
	return {$: 7, a: a};
};
var $author$project$Creator$TouchMove = function (a) {
	return {$: 5, a: a};
};
var $author$project$Creator$TouchStart = function (a) {
	return {$: 4, a: a};
};
var $author$project$Creator$dragEvents = A6($author$project$BoardHtml$DragEvents, $author$project$Creator$MoveStarted, $author$project$Creator$MoveCanceled, $author$project$Creator$TouchStart, $author$project$Creator$TouchMove, $author$project$Creator$TouchEnd, $author$project$Creator$NoOp);
var $author$project$BoardHtml$DropEvents = F2(
	function (moveTargetChanged, moveCompleted) {
		return {br: moveCompleted, bt: moveTargetChanged};
	});
var $author$project$Creator$dropEvents = A2($author$project$BoardHtml$DropEvents, $author$project$Creator$MoveTargetChanged, $author$project$Creator$MoveCompleted);
var $visotype$elm_dom$Dom$element = function (tag) {
	return {I: _List_Nil, cw: _List_Nil, A: _List_Nil, ag: '', cX: _List_Nil, b: _List_Nil, c6: '', b4: _List_Nil, aK: tag, aL: ''};
};
var $author$project$BoardHtml$BoardOverlayModel = F4(
	function (isDragging, coords, overlay, dragEvents) {
		return {aY: coords, l: dragEvents, L: isDragging, f: overlay};
	});
var $author$project$BoardHtml$PieceModel = F4(
	function (isDragging, coords, piece, dragEvents) {
		return {aY: coords, l: dragEvents, L: isDragging, N: piece};
	});
var $author$project$BoardHtml$ScenarioMonsterModel = F4(
	function (isDragging, coords, monster, dragEvents) {
		return {aY: coords, l: dragEvents, L: isDragging, m: monster};
	});
var $visotype$elm_dom$Dom$addAttribute = function (a) {
	return $visotype$elm_dom$Dom$Internal$modify(
		function (n) {
			return _Utils_update(
				n,
				{
					I: A2(
						$elm$core$List$append,
						n.I,
						_List_fromArray(
							[a]))
				});
		});
};
var $elm$virtual_dom$VirtualDom$attribute = F2(
	function (key, value) {
		return A2(
			_VirtualDom_attribute,
			_VirtualDom_noOnOrFormAction(key),
			_VirtualDom_noJavaScriptOrHtmlUri(value));
	});
var $elm$html$Html$Attributes$attribute = $elm$virtual_dom$VirtualDom$attribute;
var $author$project$BoardHtml$cellValueToString = F2(
	function (passable, hidden) {
		return hidden ? 'hidden' : (passable ? 'passable' : 'impassable');
	});
var $author$project$BoardHtml$filterOverlaysForCoord = F3(
	function (x, y, overlay) {
		var _v0 = $elm$core$List$head(
			A2(
				$elm$core$List$filter,
				function (_v1) {
					var oX = _v1.a;
					var oY = _v1.b;
					return _Utils_eq(oX, x) && _Utils_eq(oY, y);
				},
				overlay.S));
		if (!_v0.$) {
			return true;
		} else {
			return false;
		}
	});
var $author$project$BoardHtml$getPieceForCoord = F3(
	function (x, y, pieces) {
		return $elm$core$List$head(
			A2(
				$elm$core$List$filter,
				function (p) {
					return _Utils_eq(p.ci, x) && _Utils_eq(p.cj, y);
				},
				pieces));
	});
var $author$project$BoardHtml$getScenarioMonsterForCoord = F3(
	function (x, y, monsters) {
		return $elm$core$List$head(
			A2(
				$elm$core$List$filter,
				function (m) {
					return _Utils_eq(m.be, x) && _Utils_eq(m.bf, y);
				},
				monsters));
	});
var $author$project$BoardHtml$getSortOrderForOverlay = function (overlay) {
	switch (overlay.$) {
		case 9:
			return 0;
		case 1:
			return 1;
		case 2:
			return 2;
		case 0:
			return 3;
		case 6:
			return 4;
		case 5:
			return 5;
		case 8:
			var t = overlay.a;
			if (!t.$) {
				return 6;
			} else {
				return 7;
			}
		case 4:
			return 8;
		case 7:
			return 9;
		case 10:
			return 10;
		default:
			return 11;
	}
};
var $mpizenberg$elm_pointer_events$Html$Events$Extra$Drag$DropTargetConfig = F5(
	function (dropEffect, onOver, onDrop, onEnter, onLeave) {
		return {cF: dropEffect, ai: onDrop, aj: onEnter, ak: onLeave, al: onOver};
	});
var $mpizenberg$elm_pointer_events$Html$Events$Extra$Drag$MoveOnDrop = 1;
var $visotype$elm_dom$Dom$addAttributeList = function (la) {
	return $visotype$elm_dom$Dom$Internal$modify(
		function (n) {
			return _Utils_update(
				n,
				{
					I: A2($elm$core$List$append, n.I, la)
				});
		});
};
var $elm$html$Html$Events$custom = F2(
	function (event, decoder) {
		return A2(
			$elm$virtual_dom$VirtualDom$on,
			event,
			$elm$virtual_dom$VirtualDom$Custom(decoder));
	});
var $mpizenberg$elm_pointer_events$Html$Events$Extra$Drag$Event = F2(
	function (dataTransfer, mouseEvent) {
		return {cz: dataTransfer, c4: mouseEvent};
	});
var $mpizenberg$elm_pointer_events$Html$Events$Extra$Drag$DataTransfer = F3(
	function (files, types, dropEffect) {
		return {cF: dropEffect, cO: files, _: types};
	});
var $elm$file$File$decoder = _File_decoder;
var $mpizenberg$elm_pointer_events$Internal$Decode$all = A2(
	$elm$core$List$foldr,
	$elm$json$Json$Decode$map2($elm$core$List$cons),
	$elm$json$Json$Decode$succeed(_List_Nil));
var $mpizenberg$elm_pointer_events$Internal$Decode$dynamicListOf = function (itemDecoder) {
	var decodeOne = function (n) {
		return A2(
			$elm$json$Json$Decode$field,
			$elm$core$String$fromInt(n),
			itemDecoder);
	};
	var decodeN = function (n) {
		return $mpizenberg$elm_pointer_events$Internal$Decode$all(
			A2(
				$elm$core$List$map,
				decodeOne,
				A2($elm$core$List$range, 0, n - 1)));
	};
	return A2(
		$elm$json$Json$Decode$andThen,
		decodeN,
		A2($elm$json$Json$Decode$field, 'length', $elm$json$Json$Decode$int));
};
var $mpizenberg$elm_pointer_events$Html$Events$Extra$Drag$fileListDecoder = $mpizenberg$elm_pointer_events$Internal$Decode$dynamicListOf;
var $mpizenberg$elm_pointer_events$Html$Events$Extra$Drag$dataTransferDecoder = A4(
	$elm$json$Json$Decode$map3,
	$mpizenberg$elm_pointer_events$Html$Events$Extra$Drag$DataTransfer,
	A2(
		$elm$json$Json$Decode$field,
		'files',
		$mpizenberg$elm_pointer_events$Html$Events$Extra$Drag$fileListDecoder($elm$file$File$decoder)),
	A2(
		$elm$json$Json$Decode$field,
		'types',
		$elm$json$Json$Decode$list($elm$json$Json$Decode$string)),
	A2($elm$json$Json$Decode$field, 'dropEffect', $elm$json$Json$Decode$string));
var $mpizenberg$elm_pointer_events$Html$Events$Extra$Mouse$Event = F6(
	function (keys, button, clientPos, offsetPos, pagePos, screenPos) {
		return {ct: button, aX: clientPos, cX: keys, de: offsetPos, dm: pagePos, dv: screenPos};
	});
var $mpizenberg$elm_pointer_events$Html$Events$Extra$Mouse$BackButton = 4;
var $mpizenberg$elm_pointer_events$Html$Events$Extra$Mouse$ErrorButton = 0;
var $mpizenberg$elm_pointer_events$Html$Events$Extra$Mouse$ForwardButton = 5;
var $mpizenberg$elm_pointer_events$Html$Events$Extra$Mouse$MainButton = 1;
var $mpizenberg$elm_pointer_events$Html$Events$Extra$Mouse$MiddleButton = 2;
var $mpizenberg$elm_pointer_events$Html$Events$Extra$Mouse$SecondButton = 3;
var $mpizenberg$elm_pointer_events$Html$Events$Extra$Mouse$buttonFromId = function (id) {
	switch (id) {
		case 0:
			return 1;
		case 1:
			return 2;
		case 2:
			return 3;
		case 3:
			return 4;
		case 4:
			return 5;
		default:
			return 0;
	}
};
var $mpizenberg$elm_pointer_events$Html$Events$Extra$Mouse$buttonDecoder = A2(
	$elm$json$Json$Decode$map,
	$mpizenberg$elm_pointer_events$Html$Events$Extra$Mouse$buttonFromId,
	A2($elm$json$Json$Decode$field, 'button', $elm$json$Json$Decode$int));
var $mpizenberg$elm_pointer_events$Internal$Decode$clientPos = A3(
	$elm$json$Json$Decode$map2,
	F2(
		function (a, b) {
			return _Utils_Tuple2(a, b);
		}),
	A2($elm$json$Json$Decode$field, 'clientX', $elm$json$Json$Decode$float),
	A2($elm$json$Json$Decode$field, 'clientY', $elm$json$Json$Decode$float));
var $mpizenberg$elm_pointer_events$Internal$Decode$Keys = F3(
	function (alt, ctrl, shift) {
		return {co: alt, cy: ctrl, dx: shift};
	});
var $mpizenberg$elm_pointer_events$Internal$Decode$keys = A4(
	$elm$json$Json$Decode$map3,
	$mpizenberg$elm_pointer_events$Internal$Decode$Keys,
	A2($elm$json$Json$Decode$field, 'altKey', $elm$json$Json$Decode$bool),
	A2($elm$json$Json$Decode$field, 'ctrlKey', $elm$json$Json$Decode$bool),
	A2($elm$json$Json$Decode$field, 'shiftKey', $elm$json$Json$Decode$bool));
var $mpizenberg$elm_pointer_events$Internal$Decode$offsetPos = A3(
	$elm$json$Json$Decode$map2,
	F2(
		function (a, b) {
			return _Utils_Tuple2(a, b);
		}),
	A2($elm$json$Json$Decode$field, 'offsetX', $elm$json$Json$Decode$float),
	A2($elm$json$Json$Decode$field, 'offsetY', $elm$json$Json$Decode$float));
var $mpizenberg$elm_pointer_events$Internal$Decode$pagePos = A3(
	$elm$json$Json$Decode$map2,
	F2(
		function (a, b) {
			return _Utils_Tuple2(a, b);
		}),
	A2($elm$json$Json$Decode$field, 'pageX', $elm$json$Json$Decode$float),
	A2($elm$json$Json$Decode$field, 'pageY', $elm$json$Json$Decode$float));
var $mpizenberg$elm_pointer_events$Internal$Decode$screenPos = A3(
	$elm$json$Json$Decode$map2,
	F2(
		function (a, b) {
			return _Utils_Tuple2(a, b);
		}),
	A2($elm$json$Json$Decode$field, 'screenX', $elm$json$Json$Decode$float),
	A2($elm$json$Json$Decode$field, 'screenY', $elm$json$Json$Decode$float));
var $mpizenberg$elm_pointer_events$Html$Events$Extra$Mouse$eventDecoder = A7($elm$json$Json$Decode$map6, $mpizenberg$elm_pointer_events$Html$Events$Extra$Mouse$Event, $mpizenberg$elm_pointer_events$Internal$Decode$keys, $mpizenberg$elm_pointer_events$Html$Events$Extra$Mouse$buttonDecoder, $mpizenberg$elm_pointer_events$Internal$Decode$clientPos, $mpizenberg$elm_pointer_events$Internal$Decode$offsetPos, $mpizenberg$elm_pointer_events$Internal$Decode$pagePos, $mpizenberg$elm_pointer_events$Internal$Decode$screenPos);
var $mpizenberg$elm_pointer_events$Html$Events$Extra$Drag$eventDecoder = A3(
	$elm$json$Json$Decode$map2,
	$mpizenberg$elm_pointer_events$Html$Events$Extra$Drag$Event,
	A2($elm$json$Json$Decode$field, 'dataTransfer', $mpizenberg$elm_pointer_events$Html$Events$Extra$Drag$dataTransferDecoder),
	$mpizenberg$elm_pointer_events$Html$Events$Extra$Mouse$eventDecoder);
var $mpizenberg$elm_pointer_events$Html$Events$Extra$Drag$on = F2(
	function (event, tag) {
		return A2(
			$elm$html$Html$Events$custom,
			event,
			A2(
				$elm$json$Json$Decode$map,
				function (ev) {
					return {
						c1: tag(ev),
						dr: true,
						dA: true
					};
				},
				$mpizenberg$elm_pointer_events$Html$Events$Extra$Drag$eventDecoder));
	});
var $mpizenberg$elm_pointer_events$Html$Events$Extra$Drag$valuePreventedOn = F2(
	function (event, tag) {
		return A2(
			$elm$html$Html$Events$custom,
			event,
			A2(
				$elm$json$Json$Decode$map,
				function (value) {
					return {
						c1: tag(value),
						dr: true,
						dA: true
					};
				},
				$elm$json$Json$Decode$value));
	});
var $mpizenberg$elm_pointer_events$Html$Events$Extra$Drag$onDropTarget = function (config) {
	return A2(
		$elm$core$List$filterMap,
		$elm$core$Basics$identity,
		_List_fromArray(
			[
				$elm$core$Maybe$Just(
				A2(
					$mpizenberg$elm_pointer_events$Html$Events$Extra$Drag$valuePreventedOn,
					'dragover',
					config.al(config.cF))),
				$elm$core$Maybe$Just(
				A2($mpizenberg$elm_pointer_events$Html$Events$Extra$Drag$on, 'drop', config.ai)),
				A2(
				$elm$core$Maybe$map,
				$mpizenberg$elm_pointer_events$Html$Events$Extra$Drag$on('dragenter'),
				config.aj),
				A2(
				$elm$core$Maybe$map,
				$mpizenberg$elm_pointer_events$Html$Events$Extra$Drag$on('dragleave'),
				config.ak)
			]));
};
var $author$project$BoardHtml$makeDroppable = F3(
	function (coords, dropEvents, element) {
		var config = A5(
			$mpizenberg$elm_pointer_events$Html$Events$Extra$Drag$DropTargetConfig,
			1,
			F2(
				function (e, v) {
					return A2(
						dropEvents.bt,
						coords,
						$elm$core$Maybe$Just(
							_Utils_Tuple2(e, v)));
				}),
			$elm$core$Basics$always(dropEvents.br),
			$elm$core$Maybe$Nothing,
			$elm$core$Maybe$Nothing);
		return A2(
			$visotype$elm_dom$Dom$addAttributeList,
			$mpizenberg$elm_pointer_events$Html$Events$Extra$Drag$onDropTarget(config),
			element);
	});
var $visotype$elm_dom$Dom$addAttributeConditional = F2(
	function (a, test) {
		if (test) {
			return $visotype$elm_dom$Dom$addAttribute(a);
		} else {
			return function (x) {
				return x;
			};
		}
	});
var $visotype$elm_dom$Dom$addStyle = function (kv) {
	return $visotype$elm_dom$Dom$Internal$modify(
		function (n) {
			return _Utils_update(
				n,
				{
					b4: A2(
						$elm$core$List$append,
						n.b4,
						_List_fromArray(
							[kv]))
				});
		});
};
var $elm$html$Html$Attributes$alt = $elm$html$Html$Attributes$stringProperty('alt');
var $elm$core$String$append = _String_append;
var $visotype$elm_dom$Dom$appendText = function (s) {
	return $visotype$elm_dom$Dom$Internal$modify(
		function (n) {
			return _Utils_update(
				n,
				{
					aL: A2($elm$core$String$append, n.aL, s)
				});
		});
};
var $author$project$Colour$blue = A4($author$project$Colour$Colour, 0, 0, 255, 1);
var $author$project$Colour$green = A4($author$project$Colour$Colour, 0, 128, 0, 1);
var $author$project$Colour$indigo = A4($author$project$Colour$Colour, 75, 0, 130, 1);
var $author$project$Colour$orange = A4($author$project$Colour$Colour, 255, 165, 0, 1);
var $author$project$Colour$red = A4($author$project$Colour$Colour, 255, 0, 0, 1);
var $author$project$Colour$yellow = A4($author$project$Colour$Colour, 255, 255, 0, 1);
var $author$project$Colour$toString = function (colour) {
	return _Utils_eq(colour, $author$project$Colour$red) ? 'Red' : (_Utils_eq(colour, $author$project$Colour$blue) ? 'Blue' : (_Utils_eq(colour, $author$project$Colour$green) ? 'Green' : (_Utils_eq(colour, $author$project$Colour$yellow) ? 'Yellow' : (_Utils_eq(colour, $author$project$Colour$orange) ? 'Orange' : (_Utils_eq(colour, $author$project$Colour$indigo) ? 'Indigo' : $author$project$Colour$toHexString(colour))))));
};
var $author$project$BoardOverlay$getOverlayLabel = function (overlay) {
	switch (overlay.$) {
		case 1:
			var d = overlay.a;
			switch (d.$) {
				case 0:
					return 'Altar';
				case 5:
					return 'Stone Door';
				case 6:
					return 'Wooden Door';
				case 1:
					return 'Breakable Wall';
				case 2:
					var c = d.a;
					switch (c) {
						case 0:
							return 'Dark Corridor';
						case 1:
							return 'Earth Corridor';
						case 2:
							return 'Manmade Stone Corridor';
						case 3:
							return 'Natural Stone Corridor';
						case 4:
							return 'Pressure Plate';
						default:
							return 'Wooden Corridor';
					}
				case 3:
					return 'Dark Fog';
				default:
					return 'Light Fog';
			}
		case 0:
			var d = overlay.a;
			switch (d) {
				case 0:
					return 'Fallen Log';
				case 1:
					return 'Rubble';
				case 2:
					return 'Stairs';
				case 3:
					return 'Stairs';
				default:
					return 'Water';
			}
		case 2:
			var h = overlay.a;
			if (!h) {
				return 'Hot Coals';
			} else {
				return 'Thorns';
			}
		case 3:
			var c = overlay.a;
			return $author$project$Colour$toString(c) + ' Highlight';
		case 4:
			var o = overlay.a;
			switch (o) {
				case 0:
					return 'Altar';
				case 1:
					return 'Barrel';
				case 2:
					return 'Bookcase';
				case 3:
					return 'Boulder';
				case 4:
					return 'Boulder';
				case 5:
					return 'Boulder';
				case 6:
					return 'Bush';
				case 7:
					return 'Cabinet';
				case 8:
					return 'Crate';
				case 9:
					return 'Crystal';
				case 10:
					return 'Dark Pit';
				case 11:
					return 'Fountain';
				case 12:
					return 'Mirror';
				case 13:
					return 'Nest';
				case 14:
					return 'Pillar';
				case 15:
					return 'Rock Column';
				case 16:
					return 'Sarcophagus';
				case 17:
					return 'Sheelves';
				case 18:
					return 'Stalagmites';
				case 19:
					return 'Tree Stump';
				case 20:
					return 'Table';
				case 21:
					return 'Totem';
				case 22:
					return 'Tree';
				default:
					return 'Wall';
			}
		case 5:
			return 'Rift';
		case 6:
			return 'Starting Location';
		case 7:
			var t = overlay.a;
			switch (t) {
				case 0:
					return 'Bear Trap';
				case 2:
					return 'Spike Trap';
				default:
					return 'Poison Trap';
			}
		case 8:
			var t = overlay.a;
			if (!t.$) {
				var c = t.a;
				return 'Treasure Chest ' + function () {
					switch (c.$) {
						case 1:
							return 'Goal';
						case 2:
							return '(locked)';
						default:
							var i = c.a;
							return $elm$core$String$fromInt(i);
					}
				}();
			} else {
				var i = t.a;
				return _Utils_ap(
					$elm$core$String$fromInt(i),
					function () {
						if (i === 1) {
							return ' Coin';
						} else {
							return ' Coins';
						}
					}());
			}
		case 9:
			var t = overlay.a;
			return 'Token (' + (t + ')');
		default:
			var w = overlay.a;
			switch (w) {
				case 0:
					return 'Huge Rock Wall';
				case 1:
					return 'Iron Wall';
				case 2:
					return 'Large Rock Wall';
				case 3:
					return 'Obsidian Glass Wall';
				default:
					return 'Rock Wall';
			}
	}
};
var $author$project$BoardHtml$getLabelForOverlay = F2(
	function (overlay, coords) {
		if (!coords.$) {
			var _v1 = coords.a;
			var x = _v1.a;
			var y = _v1.b;
			return $author$project$BoardOverlay$getOverlayLabel(overlay.bJ) + (' at ' + ($elm$core$String$fromInt(x) + (', ' + $elm$core$String$fromInt(y))));
		} else {
			return 'Add new ' + $author$project$BoardOverlay$getOverlayLabel(overlay.bJ);
		}
	});
var $elm$core$Array$toIndexedList = function (array) {
	var len = array.a;
	var helper = F2(
		function (entry, _v0) {
			var index = _v0.a;
			var list = _v0.b;
			return _Utils_Tuple2(
				index - 1,
				A2(
					$elm$core$List$cons,
					_Utils_Tuple2(index, entry),
					list));
		});
	return A3(
		$elm$core$Array$foldr,
		helper,
		_Utils_Tuple2(len - 1, _List_Nil),
		array).b;
};
var $author$project$BoardHtml$getOverlayImageName = F2(
	function (overlay, coords) {
		var segmentPart = function () {
			if (!coords.$) {
				var _v6 = coords.a;
				var x = _v6.a;
				var y = _v6.b;
				var _v7 = $elm$core$List$head(
					A2(
						$elm$core$List$filter,
						function (_v8) {
							var _v9 = _v8.b;
							var oX = _v9.a;
							var oY = _v9.b;
							return _Utils_eq(oX, x) && _Utils_eq(oY, y);
						},
						$elm$core$Array$toIndexedList(
							$elm$core$Array$fromList(overlay.S))));
				if (!_v7.$) {
					var _v10 = _v7.a;
					var segment = _v10.a;
					return (segment > 0) ? ('-' + $elm$core$String$fromInt(segment + 1)) : '';
				} else {
					return '';
				}
			} else {
				return '';
			}
		}();
		var path = '/img/overlays/';
		var overlayName = A2(
			$elm$core$Maybe$withDefault,
			'',
			$author$project$BoardOverlay$getBoardOverlayName(overlay.bJ));
		var extension = '.png';
		var extendedOverlayName = function () {
			if ((overlay.aw === 2) || (overlay.aw === 3)) {
				var _v0 = overlay.bJ;
				_v0$4:
				while (true) {
					switch (_v0.$) {
						case 1:
							switch (_v0.a.$) {
								case 5:
									var _v1 = _v0.a;
									return '-vert';
								case 1:
									var _v2 = _v0.a;
									return '-vert';
								case 6:
									var _v3 = _v0.a;
									return '-vert';
								default:
									break _v0$4;
							}
						case 4:
							if (!_v0.a) {
								var _v4 = _v0.a;
								return '-vert';
							} else {
								break _v0$4;
							}
						default:
							break _v0$4;
					}
				}
				return '';
			} else {
				return '';
			}
		}();
		return _Utils_ap(
			path,
			_Utils_ap(
				overlayName,
				_Utils_ap(
					extendedOverlayName,
					_Utils_ap(segmentPart, extension))));
	});
var $mpizenberg$elm_pointer_events$Html$Events$Extra$Drag$DraggedSourceConfig = F4(
	function (effectAllowed, onStart, onEnd, onDrag) {
		return {cG: effectAllowed, bw: onDrag, bx: onEnd, by: onStart};
	});
var $mpizenberg$elm_pointer_events$Html$Events$Extra$Drag$EffectAllowed = F3(
	function (move, copy, link) {
		return {aZ: copy, bk: link, bp: move};
	});
var $mpizenberg$elm_pointer_events$Html$Events$Extra$Touch$defaultOptions = {dr: true, dA: false};
var $mpizenberg$elm_pointer_events$Html$Events$Extra$Touch$Event = F4(
	function (keys, changedTouches, targetTouches, touches) {
		return {cv: changedTouches, cX: keys, dE: targetTouches, dK: touches};
	});
var $mpizenberg$elm_pointer_events$Html$Events$Extra$Touch$Touch = F4(
	function (identifier, clientPos, pagePos, screenPos) {
		return {aX: clientPos, cQ: identifier, dm: pagePos, dv: screenPos};
	});
var $mpizenberg$elm_pointer_events$Html$Events$Extra$Touch$touchDecoder = A5(
	$elm$json$Json$Decode$map4,
	$mpizenberg$elm_pointer_events$Html$Events$Extra$Touch$Touch,
	A2($elm$json$Json$Decode$field, 'identifier', $elm$json$Json$Decode$int),
	$mpizenberg$elm_pointer_events$Internal$Decode$clientPos,
	$mpizenberg$elm_pointer_events$Internal$Decode$pagePos,
	$mpizenberg$elm_pointer_events$Internal$Decode$screenPos);
var $mpizenberg$elm_pointer_events$Html$Events$Extra$Touch$touchListDecoder = $mpizenberg$elm_pointer_events$Internal$Decode$dynamicListOf;
var $mpizenberg$elm_pointer_events$Html$Events$Extra$Touch$eventDecoder = A5(
	$elm$json$Json$Decode$map4,
	$mpizenberg$elm_pointer_events$Html$Events$Extra$Touch$Event,
	$mpizenberg$elm_pointer_events$Internal$Decode$keys,
	A2(
		$elm$json$Json$Decode$field,
		'changedTouches',
		$mpizenberg$elm_pointer_events$Html$Events$Extra$Touch$touchListDecoder($mpizenberg$elm_pointer_events$Html$Events$Extra$Touch$touchDecoder)),
	A2(
		$elm$json$Json$Decode$field,
		'targetTouches',
		$mpizenberg$elm_pointer_events$Html$Events$Extra$Touch$touchListDecoder($mpizenberg$elm_pointer_events$Html$Events$Extra$Touch$touchDecoder)),
	A2(
		$elm$json$Json$Decode$field,
		'touches',
		$mpizenberg$elm_pointer_events$Html$Events$Extra$Touch$touchListDecoder($mpizenberg$elm_pointer_events$Html$Events$Extra$Touch$touchDecoder)));
var $mpizenberg$elm_pointer_events$Html$Events$Extra$Touch$onWithOptions = F3(
	function (event, options, tag) {
		return A2(
			$elm$html$Html$Events$custom,
			event,
			A2(
				$elm$json$Json$Decode$map,
				function (ev) {
					return {
						c1: tag(ev),
						dr: options.dr,
						dA: options.dA
					};
				},
				$mpizenberg$elm_pointer_events$Html$Events$Extra$Touch$eventDecoder));
	});
var $mpizenberg$elm_pointer_events$Html$Events$Extra$Touch$onEnd = A2($mpizenberg$elm_pointer_events$Html$Events$Extra$Touch$onWithOptions, 'touchend', $mpizenberg$elm_pointer_events$Html$Events$Extra$Touch$defaultOptions);
var $mpizenberg$elm_pointer_events$Html$Events$Extra$Touch$onMove = A2($mpizenberg$elm_pointer_events$Html$Events$Extra$Touch$onWithOptions, 'touchmove', $mpizenberg$elm_pointer_events$Html$Events$Extra$Touch$defaultOptions);
var $elm$html$Html$Attributes$draggable = _VirtualDom_attribute('draggable');
var $mpizenberg$elm_pointer_events$Html$Events$Extra$Drag$valueOn = F2(
	function (event, tag) {
		return A2(
			$elm$html$Html$Events$custom,
			event,
			A2(
				$elm$json$Json$Decode$map,
				function (value) {
					return {
						c1: tag(value),
						dr: false,
						dA: true
					};
				},
				$elm$json$Json$Decode$value));
	});
var $mpizenberg$elm_pointer_events$Html$Events$Extra$Drag$onSourceDrag = function (config) {
	return A2(
		$elm$core$List$filterMap,
		$elm$core$Basics$identity,
		_List_fromArray(
			[
				$elm$core$Maybe$Just(
				$elm$html$Html$Attributes$draggable('true')),
				$elm$core$Maybe$Just(
				A2(
					$mpizenberg$elm_pointer_events$Html$Events$Extra$Drag$valueOn,
					'dragstart',
					config.by(config.cG))),
				$elm$core$Maybe$Just(
				A2($mpizenberg$elm_pointer_events$Html$Events$Extra$Drag$on, 'dragend', config.bx)),
				A2(
				$elm$core$Maybe$map,
				$mpizenberg$elm_pointer_events$Html$Events$Extra$Drag$on('drag'),
				config.bw)
			]));
};
var $mpizenberg$elm_pointer_events$Html$Events$Extra$Touch$onStart = A2($mpizenberg$elm_pointer_events$Html$Events$Extra$Touch$onWithOptions, 'touchstart', $mpizenberg$elm_pointer_events$Html$Events$Extra$Touch$defaultOptions);
var $author$project$BoardHtml$makeDraggable = F4(
	function (piece, coords, dragEvents, element) {
		var config = A4(
			$mpizenberg$elm_pointer_events$Html$Events$Extra$Drag$DraggedSourceConfig,
			A3($mpizenberg$elm_pointer_events$Html$Events$Extra$Drag$EffectAllowed, true, false, false),
			F2(
				function (e, v) {
					return A2(
						dragEvents.bs,
						A3($author$project$AppStorage$MoveablePiece, piece, coords, $elm$core$Maybe$Nothing),
						$elm$core$Maybe$Just(
							_Utils_Tuple2(e, v)));
				}),
			$elm$core$Basics$always(dragEvents.bq),
			$elm$core$Maybe$Nothing);
		return A2(
			$visotype$elm_dom$Dom$addAttribute,
			$mpizenberg$elm_pointer_events$Html$Events$Extra$Touch$onEnd(
				function (e) {
					var _v2 = $elm$core$List$head(e.cv);
					if (!_v2.$) {
						var touch = _v2.a;
						return dragEvents.ca(touch.aX);
					} else {
						return dragEvents.aE;
					}
				}),
			A2(
				$visotype$elm_dom$Dom$addAttribute,
				$mpizenberg$elm_pointer_events$Html$Events$Extra$Touch$onMove(
					function (e) {
						var _v1 = $elm$core$List$head(e.dK);
						if (!_v1.$) {
							var touch = _v1.a;
							return dragEvents.cb(touch.aX);
						} else {
							return dragEvents.aE;
						}
					}),
				A2(
					$visotype$elm_dom$Dom$addAttribute,
					$mpizenberg$elm_pointer_events$Html$Events$Extra$Touch$onStart(
						function (_v0) {
							return dragEvents.cc(
								A3($author$project$AppStorage$MoveablePiece, piece, coords, $elm$core$Maybe$Nothing));
						}),
					A2(
						$visotype$elm_dom$Dom$addAttributeList,
						$mpizenberg$elm_pointer_events$Html$Events$Extra$Drag$onSourceDrag(config),
						element))));
	});
var $author$project$BoardHtml$overlayToHtml = F3(
	function (dragOverlays, dragDoors, model) {
		var label = A2($author$project$BoardHtml$getLabelForOverlay, model.f, model.aY);
		return _Utils_Tuple2(
			label,
			function () {
				if (dragDoors) {
					var _v11 = model.f.bJ;
					if (_v11.$ === 1) {
						return A3(
							$author$project$BoardHtml$makeDraggable,
							A2($author$project$AppStorage$OverlayType, model.f, $elm$core$Maybe$Nothing),
							model.aY,
							model.l);
					} else {
						return dragOverlays ? function (e) {
							return e;
						} : $visotype$elm_dom$Dom$addAttribute(
							A2($elm$html$Html$Attributes$attribute, 'draggable', 'false'));
					}
				} else {
					return function (e) {
						return e;
					};
				}
			}()(
				function () {
					if (dragOverlays) {
						var _v10 = model.f.bJ;
						switch (_v10.$) {
							case 8:
								if (_v10.a.$ === 1) {
									return _Utils_eq(model.aY, $elm$core$Maybe$Nothing) ? A3(
										$author$project$BoardHtml$makeDraggable,
										A2($author$project$AppStorage$OverlayType, model.f, $elm$core$Maybe$Nothing),
										model.aY,
										model.l) : $visotype$elm_dom$Dom$addAttribute(
										A2($elm$html$Html$Attributes$attribute, 'draggable', 'false'));
								} else {
									return $visotype$elm_dom$Dom$addAttribute(
										A2($elm$html$Html$Attributes$attribute, 'draggable', 'false'));
								}
							case 3:
								return $visotype$elm_dom$Dom$addAttribute(
									A2($elm$html$Html$Attributes$attribute, 'draggable', 'false'));
							case 1:
								return dragDoors ? function (e) {
									return e;
								} : $visotype$elm_dom$Dom$addAttribute(
									A2($elm$html$Html$Attributes$attribute, 'draggable', 'false'));
							default:
								return A3(
									$author$project$BoardHtml$makeDraggable,
									A2($author$project$AppStorage$OverlayType, model.f, $elm$core$Maybe$Nothing),
									model.aY,
									model.l);
						}
					} else {
						return function (e) {
							return e;
						};
					}
				}()(
					function () {
						var _v9 = model.f.bJ;
						if ((_v9.$ === 8) && (_v9.a.$ === 1)) {
							var i = _v9.a.a;
							return $visotype$elm_dom$Dom$appendChild(
								A2(
									$visotype$elm_dom$Dom$appendText,
									$elm$core$String$fromInt(i),
									$visotype$elm_dom$Dom$element('span')));
						} else {
							return function (e) {
								return e;
							};
						}
					}()(
						A2(
							$visotype$elm_dom$Dom$appendChild,
							function () {
								var _v8 = model.f.bJ;
								switch (_v8.$) {
									case 9:
										var val = _v8.a;
										return A2(
											$visotype$elm_dom$Dom$appendText,
											val,
											$visotype$elm_dom$Dom$element('span'));
									case 3:
										var c = _v8.a;
										return A2(
											$visotype$elm_dom$Dom$addStyle,
											_Utils_Tuple2(
												'background-color',
												$author$project$Colour$toHexString(c)),
											$visotype$elm_dom$Dom$element('div'));
									default:
										return A2(
											$visotype$elm_dom$Dom$addAttribute,
											A2($elm$html$Html$Attributes$attribute, 'draggable', 'false'),
											A2(
												$visotype$elm_dom$Dom$addAttribute,
												A2(
													$elm$html$Html$Attributes$attribute,
													'src',
													A2($author$project$BoardHtml$getOverlayImageName, model.f, model.aY)),
												A2(
													$visotype$elm_dom$Dom$addAttribute,
													$elm$html$Html$Attributes$alt(
														$author$project$BoardOverlay$getOverlayLabel(model.f.bJ)),
													$visotype$elm_dom$Dom$element('img'))));
								}
							}(),
							A3(
								$visotype$elm_dom$Dom$addAttributeConditional,
								A2(
									$elm$html$Html$Attributes$attribute,
									'data-index',
									function () {
										var _v4 = model.f.bJ;
										if (_v4.$ === 8) {
											var t = _v4.a;
											if (!t.$) {
												var c = t.a;
												switch (c.$) {
													case 0:
														var i = c.a;
														return $elm$core$String$fromInt(i);
													case 1:
														return 'Goal';
													default:
														return '???';
												}
											} else {
												return '';
											}
										} else {
											return '';
										}
									}()),
								function () {
									var _v7 = model.f.bJ;
									if (_v7.$ === 8) {
										return true;
									} else {
										return false;
									}
								}(),
								A2(
									$visotype$elm_dom$Dom$addClass,
									function () {
										var _v3 = model.f.aw;
										switch (_v3) {
											case 0:
												return '';
											case 2:
												return 'vertical';
											case 3:
												return 'vertical-reverse';
											case 1:
												return 'horizontal';
											case 5:
												return 'diagonal-right';
											case 4:
												return 'diagonal-left';
											case 7:
												return 'diagonal-right-reverse';
											default:
												return 'diagonal-left-reverse';
										}
									}(),
									A2(
										$visotype$elm_dom$Dom$addClass,
										function () {
											var _v0 = model.f.bJ;
											switch (_v0.$) {
												case 6:
													return 'start-location';
												case 5:
													return 'rift';
												case 8:
													var t = _v0.a;
													return 'treasure ' + function () {
														if (t.$ === 1) {
															return 'coin';
														} else {
															return 'chest';
														}
													}();
												case 4:
													return 'obstacle';
												case 2:
													return 'hazard';
												case 3:
													return 'highlight';
												case 0:
													return 'difficult-terrain';
												case 1:
													var c = _v0.a;
													return 'door' + function () {
														if (c.$ === 2) {
															return ' corridor';
														} else {
															return '';
														}
													}();
												case 7:
													return 'trap';
												case 9:
													return 'token';
												default:
													return 'wall';
											}
										}(),
										A3(
											$visotype$elm_dom$Dom$addClassConditional,
											'being-dragged',
											model.L,
											A2(
												$visotype$elm_dom$Dom$addClass,
												'overlay',
												A2(
													$visotype$elm_dom$Dom$addAttribute,
													A2($elm$html$Html$Attributes$attribute, 'aria-label', label),
													$visotype$elm_dom$Dom$element('div'))))))))))));
	});
var $visotype$elm_dom$Dom$appendChildList = function (le) {
	var lr = A2($elm$core$List$map, $visotype$elm_dom$Dom$Internal$render, le);
	return $visotype$elm_dom$Dom$Internal$modify(
		function (n) {
			return _Utils_update(
				n,
				{
					cw: A2($elm$core$List$append, n.cw, lr)
				});
		});
};
var $author$project$BoardHtml$enemyToHtml = F3(
	function (monster, altText, element) {
		var _class = function () {
			var _v0 = monster.m;
			if (!_v0.$) {
				var _v1 = monster.bj;
				switch (_v1) {
					case 2:
						return 'elite';
					case 1:
						return 'normal';
					default:
						return '';
				}
			} else {
				return 'boss';
			}
		}();
		return A2(
			$visotype$elm_dom$Dom$appendChildList,
			_List_fromArray(
				[
					A2(
					$visotype$elm_dom$Dom$addAttribute,
					$elm$html$Html$Attributes$alt(altText),
					A2(
						$visotype$elm_dom$Dom$addAttribute,
						A2(
							$elm$html$Html$Attributes$attribute,
							'src',
							'/img/monsters/' + (A2(
								$elm$core$Maybe$withDefault,
								'',
								$author$project$Monster$monsterTypeToString(monster.m)) + '.png')),
						$visotype$elm_dom$Dom$element('img'))),
					A2(
					$visotype$elm_dom$Dom$appendText,
					(!monster.ag) ? '' : $elm$core$String$fromInt(monster.ag),
					$visotype$elm_dom$Dom$element('span'))
				]),
			A2(
				$visotype$elm_dom$Dom$addClass,
				'hex-mask',
				A2($visotype$elm_dom$Dom$addClass, _class, element)));
	});
var $author$project$BoardHtml$getLabelForPiece = function (piece) {
	var _v0 = piece.bJ;
	switch (_v0.$) {
		case 1:
			var p = _v0.a;
			return A3(
				$elm$core$String$replace,
				'-',
				' ',
				A2(
					$elm$core$Maybe$withDefault,
					'',
					$author$project$Character$characterToString(p)));
		case 2:
			var t = _v0.a;
			if (!t.$) {
				var m = t.a;
				return function () {
					var _v2 = m.m;
					if (!_v2.$) {
						var _v3 = m.bj;
						switch (_v3) {
							case 2:
								return 'Elite';
							case 1:
								return 'Normal';
							default:
								return '';
						}
					} else {
						return 'Boss';
					}
				}() + (' ' + (A3(
					$elm$core$String$replace,
					'-',
					' ',
					A2(
						$elm$core$Maybe$withDefault,
						'',
						$author$project$Monster$monsterTypeToString(m.m))) + ((m.ag > 0) ? (' (' + ($elm$core$String$fromInt(m.ag) + ')')) : '')));
			} else {
				if (!t.a.$) {
					var _v4 = t.a;
					var i = _v4.a;
					return 'Summons Number ' + $elm$core$String$fromInt(i);
				} else {
					var _v5 = t.a;
					return 'Beast Tyrant Bear Summons';
				}
			}
		default:
			return 'None';
	}
};
var $author$project$Game$getPieceName = function (piece) {
	switch (piece.$) {
		case 1:
			var p = piece.a;
			return A2(
				$elm$core$Maybe$withDefault,
				'',
				$author$project$Character$characterToString(p));
		case 2:
			var t = piece.a;
			if (t.$ === 1) {
				return 'summons';
			} else {
				var e = t.a;
				return A2(
					$elm$core$Maybe$withDefault,
					'',
					$author$project$Monster$monsterTypeToString(e.m));
			}
		default:
			return '';
	}
};
var $author$project$Game$getPieceType = function (piece) {
	switch (piece.$) {
		case 1:
			return 'player';
		case 2:
			var t = piece.a;
			if (t.$ === 1) {
				return 'player';
			} else {
				return 'monster';
			}
		default:
			return '';
	}
};
var $author$project$BoardHtml$pieceToHtml = F2(
	function (dragPiece, model) {
		var playerHtml = F3(
			function (l, p, e) {
				return A2(
					$visotype$elm_dom$Dom$appendChild,
					A2(
						$visotype$elm_dom$Dom$addAttribute,
						A2($elm$html$Html$Attributes$attribute, 'src', '/img/characters/portraits/' + (p + '.png')),
						A2(
							$visotype$elm_dom$Dom$addAttribute,
							$elm$html$Html$Attributes$alt(l),
							$visotype$elm_dom$Dom$element('img'))),
					A2($visotype$elm_dom$Dom$addClass, 'hex-mask', e));
			});
		var label = $author$project$BoardHtml$getLabelForPiece(model.N);
		return _Utils_Tuple2(
			label,
			(dragPiece ? A3(
				$author$project$BoardHtml$makeDraggable,
				$author$project$AppStorage$PieceType(model.N),
				model.aY,
				model.l) : function (e) {
				return e;
			})(
				function () {
					var _v2 = model.N.bJ;
					switch (_v2.$) {
						case 1:
							var p = _v2.a;
							return A2(
								playerHtml,
								label,
								A2(
									$elm$core$Maybe$withDefault,
									'',
									$author$project$Character$characterToString(p)));
						case 2:
							var t = _v2.a;
							if (!t.$) {
								var m = t.a;
								return A2($author$project$BoardHtml$enemyToHtml, m, label);
							} else {
								if (!t.a.$) {
									var _v4 = t.a;
									var i = _v4.a;
									var colour = _v4.b;
									return $visotype$elm_dom$Dom$appendChildList(
										_List_fromArray(
											[
												A2(
												$visotype$elm_dom$Dom$addAttribute,
												A2($elm$html$Html$Attributes$attribute, 'draggable', 'false'),
												A2(
													$visotype$elm_dom$Dom$addAttribute,
													A2($elm$html$Html$Attributes$attribute, 'src', '/img/characters/summons.png'),
													A2(
														$visotype$elm_dom$Dom$addAttribute,
														$elm$html$Html$Attributes$alt(label),
														$visotype$elm_dom$Dom$element('img')))),
												A2(
												$visotype$elm_dom$Dom$appendText,
												$elm$core$String$fromInt(i),
												$visotype$elm_dom$Dom$element('span'))
											]));
								} else {
									var _v5 = t.a;
									return function (e) {
										return A3(
											playerHtml,
											label,
											'bear',
											A2($visotype$elm_dom$Dom$addClass, 'bear', e));
									};
								}
							}
						default:
							return $visotype$elm_dom$Dom$addClass('none');
					}
				}()(
					A3(
						$visotype$elm_dom$Dom$addClassConditional,
						'being-dragged',
						model.L,
						A2(
							$visotype$elm_dom$Dom$addClass,
							$author$project$Game$getPieceName(model.N.bJ),
							A2(
								$visotype$elm_dom$Dom$addClass,
								$author$project$Game$getPieceType(model.N.bJ),
								A2(
									$visotype$elm_dom$Dom$addAttribute,
									A2(
										$elm$html$Html$Attributes$attribute,
										'aria-label',
										function () {
											var _v0 = model.aY;
											if (!_v0.$) {
												var _v1 = _v0.a;
												var x = _v1.a;
												var y = _v1.b;
												return label + (' at ' + ($elm$core$String$fromInt(x) + (', ' + $elm$core$String$fromInt(y))));
											} else {
												return 'Add New ' + label;
											}
										}()),
									$visotype$elm_dom$Dom$element('div'))))))));
	});
var $author$project$BoardHtml$scenarioMonsterVisibilityToHtml = function (level) {
	return A2(
		$visotype$elm_dom$Dom$addClass,
		function () {
			switch (level) {
				case 1:
					return 'normal';
				case 2:
					return 'elite';
				default:
					return 'none';
			}
		}(),
		A2(
			$visotype$elm_dom$Dom$addClass,
			'monster-visibility',
			$visotype$elm_dom$Dom$element('div')));
};
var $author$project$BoardHtml$scenarioMonsterToHtml = F2(
	function (dragPiece, model) {
		var monster = model.m;
		var pieceModel = {
			bJ: $author$project$Game$AI(
				$author$project$Game$Enemy(monster.m)),
			ci: monster.be,
			cj: monster.bf
		};
		var label = A3(
			$elm$core$String$replace,
			'-',
			' ',
			A2(
				$elm$core$Maybe$withDefault,
				'',
				$author$project$Monster$monsterTypeToString(monster.m.m)));
		return _Utils_Tuple2(
			label,
			(dragPiece ? A3(
				$author$project$BoardHtml$makeDraggable,
				$author$project$AppStorage$PieceType(pieceModel),
				model.aY,
				model.l) : function (e) {
				return e;
			})(
				A2(
					$visotype$elm_dom$Dom$appendChild,
					A2(
						$visotype$elm_dom$Dom$addClass,
						'four-player',
						$author$project$BoardHtml$scenarioMonsterVisibilityToHtml(monster.cP)),
					A2(
						$visotype$elm_dom$Dom$appendChild,
						A2(
							$visotype$elm_dom$Dom$addClass,
							'three-player',
							$author$project$BoardHtml$scenarioMonsterVisibilityToHtml(monster.dF)),
						A2(
							$visotype$elm_dom$Dom$appendChild,
							A2(
								$visotype$elm_dom$Dom$addClass,
								'two-player',
								$author$project$BoardHtml$scenarioMonsterVisibilityToHtml(monster.dM)),
							A3(
								$author$project$BoardHtml$enemyToHtml,
								monster.m,
								label,
								A3(
									$visotype$elm_dom$Dom$addClassConditional,
									'being-dragged',
									model.L,
									A2(
										$visotype$elm_dom$Dom$addClass,
										A2(
											$elm$core$Maybe$withDefault,
											'',
											$author$project$Monster$monsterTypeToString(model.m.m.m)),
										A2(
											$visotype$elm_dom$Dom$addClass,
											'monster',
											A2(
												$visotype$elm_dom$Dom$addAttribute,
												A2(
													$elm$html$Html$Attributes$attribute,
													'aria-label',
													function () {
														var _v0 = model.aY;
														if (!_v0.$) {
															var _v1 = _v0.a;
															var x = _v1.a;
															var y = _v1.b;
															return label + (' at ' + ($elm$core$String$fromInt(x) + (', ' + $elm$core$String$fromInt(y))));
														} else {
															return 'Add New ' + label;
														}
													}()),
												$visotype$elm_dom$Dom$element('div')))))))))));
	});
var $elm$core$List$unzip = function (pairs) {
	var step = F2(
		function (_v0, _v1) {
			var x = _v0.a;
			var y = _v0.b;
			var xs = _v1.a;
			var ys = _v1.b;
			return _Utils_Tuple2(
				A2($elm$core$List$cons, x, xs),
				A2($elm$core$List$cons, y, ys));
		});
	return A3(
		$elm$core$List$foldr,
		step,
		_Utils_Tuple2(_List_Nil, _List_Nil),
		pairs);
};
var $visotype$elm_dom$Dom$setChildListWithKeys = function (lkv) {
	var _v0 = $elm$core$List$unzip(lkv);
	var ls = _v0.a;
	var le = _v0.b;
	var lr = A2($elm$core$List$map, $visotype$elm_dom$Dom$Internal$render, le);
	return $visotype$elm_dom$Dom$Internal$modify(
		function (n) {
			return _Utils_update(
				n,
				{cw: lr, cX: ls});
		});
};
var $elm$core$List$sortWith = _List_sortWith;
var $author$project$BoardHtml$getCellHtml = function (model) {
	var currentDraggable = model.a_;
	var _v0 = model.aY;
	var x = _v0.a;
	var y = _v0.b;
	var monster = A2(
		$elm$core$Maybe$map,
		function (m) {
			return A4(
				$author$project$BoardHtml$ScenarioMonsterModel,
				function () {
					if (!currentDraggable.$) {
						var c = currentDraggable.a;
						var _v18 = c.bJ;
						if (_v18.$ === 1) {
							var p = _v18.a;
							var _v19 = p.bJ;
							if ((_v19.$ === 2) && (!_v19.a.$)) {
								var e = _v19.a.a;
								return _Utils_eq(e, m.m);
							} else {
								return false;
							}
						} else {
							return false;
						}
					} else {
						return false;
					}
				}(),
				$elm$core$Maybe$Just(
					_Utils_Tuple2(x, y)),
				m,
				model.l);
		},
		A3($author$project$BoardHtml$getScenarioMonsterForCoord, x, y, model.bY));
	var overlaysForCell = A2(
		$elm$core$List$map,
		function (o) {
			return A4(
				$author$project$BoardHtml$BoardOverlayModel,
				function () {
					if (!currentDraggable.$) {
						var m = currentDraggable.a;
						var _v12 = m.bJ;
						if (!_v12.$) {
							var ot = _v12.a;
							var isInTarget = function () {
								var _v15 = m.b9;
								if (!_v15.$) {
									var _v16 = _v15.a;
									var ox = _v16.a;
									var oy = _v16.b;
									return A2(
										$elm$core$List$any,
										function (c) {
											return _Utils_eq(
												c,
												_Utils_Tuple2(ox, oy));
										},
										o.S);
								} else {
									return false;
								}
							}();
							var isInCoords = function () {
								var _v13 = m.aY;
								if (!_v13.$) {
									var _v14 = _v13.a;
									var ox = _v14.a;
									var oy = _v14.b;
									return A2(
										$elm$core$List$any,
										function (c) {
											return _Utils_eq(
												c,
												_Utils_Tuple2(ox, oy));
										},
										o.S);
								} else {
									return false;
								}
							}();
							return _Utils_eq(ot.bJ, o.bJ) && (isInCoords || isInTarget);
						} else {
							return false;
						}
					} else {
						return false;
					}
				}(),
				$elm$core$Maybe$Just(
					_Utils_Tuple2(x, y)),
				o,
				model.l);
		},
		A2(
			$elm$core$List$filter,
			A2($author$project$BoardHtml$filterOverlaysForCoord, x, y),
			model.bA));
	var piece = A2(
		$elm$core$Maybe$map,
		function (p) {
			return A4(
				$author$project$BoardHtml$PieceModel,
				function () {
					if (!currentDraggable.$) {
						var m = currentDraggable.a;
						var _v10 = m.bJ;
						if (_v10.$ === 1) {
							var pieceType = _v10.a;
							return _Utils_eq(pieceType.bJ, p.bJ);
						} else {
							return false;
						}
					} else {
						return false;
					}
				}(),
				$elm$core$Maybe$Just(
					_Utils_Tuple2(x, y)),
				p,
				model.l);
		},
		A3($author$project$BoardHtml$getPieceForCoord, x, y, model.bD));
	var cellElement = A2(
		$visotype$elm_dom$Dom$setChildListWithKeys,
		_Utils_ap(
			A2(
				$elm$core$List$map,
				A2($author$project$BoardHtml$overlayToHtml, model.ad, model.ac),
				A2(
					$elm$core$List$filter,
					function (o) {
						var _v1 = o.f.bJ;
						switch (_v1.$) {
							case 8:
								var t = _v1.a;
								if (!t.$) {
									return true;
								} else {
									return false;
								}
							case 9:
								return false;
							default:
								return true;
						}
					},
					A2(
						$elm$core$List$sortWith,
						F2(
							function (a, b) {
								return A2(
									$elm$core$Basics$compare,
									$author$project$BoardHtml$getSortOrderForOverlay(a.f.bJ),
									$author$project$BoardHtml$getSortOrderForOverlay(b.f.bJ));
							}),
						overlaysForCell))),
			_Utils_ap(
				function () {
					if (piece.$ === 1) {
						return _List_Nil;
					} else {
						var p = piece.a;
						return _List_fromArray(
							[
								A2($author$project$BoardHtml$pieceToHtml, model.ae, p)
							]);
					}
				}(),
				_Utils_ap(
					function () {
						if (monster.$ === 1) {
							return _List_Nil;
						} else {
							var m = monster.a;
							return _List_fromArray(
								[
									A2($author$project$BoardHtml$scenarioMonsterToHtml, model.ae, m)
								]);
						}
					}(),
					_Utils_ap(
						A2(
							$elm$core$List$map,
							A2($author$project$BoardHtml$overlayToHtml, model.ad, model.ac),
							A2(
								$elm$core$List$filter,
								function (o) {
									var _v5 = o.f.bJ;
									switch (_v5.$) {
										case 8:
											var t = _v5.a;
											if (!t.$) {
												return false;
											} else {
												return true;
											}
										case 9:
											return true;
										default:
											return false;
									}
								},
								overlaysForCell)),
						function () {
							if (!currentDraggable.$) {
								var m = currentDraggable.a;
								var _v8 = m.bJ;
								switch (_v8.$) {
									case 1:
										var p = _v8.a;
										return _Utils_eq(
											m.b9,
											$elm$core$Maybe$Just(
												_Utils_Tuple2(x, y))) ? _List_fromArray(
											[
												A2(
												$author$project$BoardHtml$pieceToHtml,
												model.ae,
												A4(
													$author$project$BoardHtml$PieceModel,
													false,
													$elm$core$Maybe$Just(
														_Utils_Tuple2(x, y)),
													p,
													model.l))
											]) : _List_Nil;
									case 0:
										var o = _v8.a;
										return A2(
											$elm$core$List$any,
											function (c) {
												return _Utils_eq(
													c,
													_Utils_Tuple2(x, y));
											},
											o.S) ? _List_fromArray(
											[
												A3(
												$author$project$BoardHtml$overlayToHtml,
												model.ad,
												model.ac,
												A4(
													$author$project$BoardHtml$BoardOverlayModel,
													false,
													$elm$core$Maybe$Just(
														_Utils_Tuple2(x, y)),
													o,
													model.l))
											]) : _List_Nil;
									default:
										return _List_Nil;
								}
							} else {
								return _List_Nil;
							}
						}())))),
		A2(
			$visotype$elm_dom$Dom$addAttribute,
			A2(
				$elm$html$Html$Attributes$attribute,
				'data-cell-y',
				$elm$core$String$fromInt(y)),
			A2(
				$visotype$elm_dom$Dom$addAttribute,
				A2(
					$elm$html$Html$Attributes$attribute,
					'data-cell-x',
					$elm$core$String$fromInt(x)),
				A2(
					$visotype$elm_dom$Dom$addClass,
					'hexagon',
					$visotype$elm_dom$Dom$element('div')))));
	return function (e) {
		return (model.aG && (!model.aA)) ? A3(
			$author$project$BoardHtml$makeDroppable,
			_Utils_Tuple2(x, y),
			model.a3,
			e) : e;
	}(
		A2(
			$visotype$elm_dom$Dom$appendChild,
			A2(
				$visotype$elm_dom$Dom$appendChild,
				cellElement,
				A2(
					$visotype$elm_dom$Dom$addClass,
					'cell',
					$visotype$elm_dom$Dom$element('div'))),
			A2(
				$visotype$elm_dom$Dom$addClass,
				A2($author$project$BoardHtml$cellValueToString, model.aG, model.aA),
				A2(
					$visotype$elm_dom$Dom$addClass,
					'cell-wrapper',
					$visotype$elm_dom$Dom$element('div')))));
};
var $visotype$elm_dom$Dom$render = $visotype$elm_dom$Dom$Internal$render;
var $author$project$Creator$getCellHtml = F8(
	function (overlays, pieces, monsters, roomOrigin, turns, encodedDraggable, x, y) {
		var ref = function () {
			var _v3 = $author$project$BoardMapTile$stringToRef(roomOrigin);
			if (!_v3.$) {
				var r = _v3.a;
				return r;
			} else {
				return 62;
			}
		}();
		var currentDraggable = function () {
			var _v2 = A2($elm$json$Json$Decode$decodeString, $author$project$AppStorage$decodeMoveablePiece, encodedDraggable);
			if (!_v2.$) {
				var d = _v2.a;
				return $elm$core$Maybe$Just(d);
			} else {
				return $elm$core$Maybe$Nothing;
			}
		}();
		var isDraggingRoom = function () {
			if (!currentDraggable.$) {
				var c = currentDraggable.a;
				var _v1 = c.bJ;
				if (_v1.$ === 2) {
					var r = _v1.a;
					return _Utils_eq(r.bJ, ref);
				} else {
					return false;
				}
			} else {
				return false;
			}
		}();
		return $visotype$elm_dom$Dom$render(
			A2(
				$visotype$elm_dom$Dom$addActionStopAndPrevent,
				_Utils_Tuple2(
					'click',
					$author$project$Creator$OpenContextMenu(
						_Utils_Tuple2(x, y))),
				A3(
					$visotype$elm_dom$Dom$appendChildConditional,
					A4(
						$author$project$BoardHtml$makeDraggable,
						$author$project$AppStorage$RoomType(
							{
								dj: _Utils_Tuple2(x, y),
								bJ: ref,
								dL: turns
							}),
						$elm$core$Maybe$Just(
							_Utils_Tuple2(x, y)),
						$author$project$Creator$dragEvents,
						A3(
							$visotype$elm_dom$Dom$addClassConditional,
							'dragging',
							isDraggingRoom,
							A2(
								$visotype$elm_dom$Dom$addClass,
								'room-origin',
								$visotype$elm_dom$Dom$element('div')))),
					ref !== 62,
					$author$project$BoardHtml$getCellHtml(
						$author$project$BoardHtml$CellModel(overlays)(pieces)(monsters)(
							_Utils_Tuple2(x, y))(currentDraggable)(true)(true)(true)($author$project$Creator$dragEvents)($author$project$Creator$dropEvents)(true)(false)))));
	});
var $elm$virtual_dom$VirtualDom$lazy8 = _VirtualDom_lazy8;
var $elm$html$Html$Lazy$lazy8 = $elm$virtual_dom$VirtualDom$lazy8;
var $elm$html$Html$Keyed$node = $elm$virtual_dom$VirtualDom$keyedNode;
var $author$project$Creator$getBoardRowHtml = F5(
	function (model, encodedDraggable, cellsForDraggable, y, row) {
		return _Utils_Tuple2(
			'board-row-' + $elm$core$String$fromInt(y),
			A3(
				$elm$html$Html$Keyed$node,
				'div',
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('row')
					]),
				A2(
					$elm$core$List$indexedMap,
					F2(
						function (x, _v0) {
							var useDraggable = A2(
								$elm$core$List$any,
								function (c) {
									return _Utils_eq(
										c,
										_Utils_Tuple2(x, y));
								},
								cellsForDraggable);
							var id = 'board-cell-' + ($elm$core$String$fromInt(x) + ('-' + $elm$core$String$fromInt(y)));
							var currentDraggable = useDraggable ? encodedDraggable : '';
							var _v1 = A2(
								$elm$core$Maybe$withDefault,
								_Utils_Tuple2('', 0),
								$elm$core$List$head(
									A2(
										$elm$core$List$filterMap,
										function (r) {
											return _Utils_eq(
												r.a$.dj,
												_Utils_Tuple2(x, y)) ? A2(
												$elm$core$Maybe$map,
												function (s) {
													return _Utils_Tuple2(s, r.a$.dL);
												},
												$author$project$BoardMapTile$refToString(r.a$.bJ)) : $elm$core$Maybe$Nothing;
										},
										model.a.bT)));
							var roomRef = _v1.a;
							var turns = _v1.b;
							return _Utils_Tuple2(
								id,
								A9($elm$html$Html$Lazy$lazy8, $author$project$Creator$getCellHtml, model.a.bA, $author$project$Creator$emptyList, model.a.bn, roomRef, turns, currentDraggable, x, y));
						}),
					row)));
	});
var $author$project$BoardHtml$FourPlayerSubMenu = 4;
var $author$project$Creator$RemoveMonster = function (a) {
	return {$: 15, a: a};
};
var $author$project$Creator$RemoveOverlay = function (a) {
	return {$: 17, a: a};
};
var $author$project$Creator$RemoveRoom = function (a) {
	return {$: 19, a: a};
};
var $author$project$Creator$RotateOverlay = function (a) {
	return {$: 16, a: a};
};
var $author$project$Creator$RotateRoom = function (a) {
	return {$: 18, a: a};
};
var $author$project$BoardHtml$ThreePlayerSubMenu = 3;
var $author$project$BoardHtml$TwoPlayerSubMenu = 2;
var $author$project$Creator$ChangeMonsterState = F3(
	function (a, b, c) {
		return {$: 13, a: a, b: b, c: c};
	});
var $elm$html$Html$li = _VirtualDom_node('li');
var $author$project$HtmlEvents$onClickPreventDefault = function (msg) {
	return A2(
		$elm$html$Html$Events$custom,
		'click',
		$elm$json$Json$Decode$succeed(
			{c1: msg, dr: true, dA: true}));
};
var $elm$html$Html$span = _VirtualDom_node('span');
var $elm$html$Html$text = $elm$virtual_dom$VirtualDom$text;
var $elm$html$Html$ul = _VirtualDom_node('ul');
var $author$project$Creator$getMonsterLevelHtml = F5(
	function (stateChange, isOpen, selectedLevel, playerSize, id) {
		return A2(
			$elm$html$Html$li,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('edit-monster has-sub-menu'),
					$author$project$HtmlEvents$onClickPreventDefault(
					$author$project$Creator$ChangeContextMenuState(stateChange))
				]),
			_List_fromArray(
				[
					A2(
					$elm$html$Html$span,
					_List_Nil,
					_List_fromArray(
						[
							$elm$html$Html$text(
							$elm$core$String$fromInt(playerSize) + ' Player State')
						])),
					A2(
					$elm$html$Html$ul,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class(
							isOpen ? 'open' : '')
						]),
					_List_fromArray(
						[
							A2(
							$elm$html$Html$li,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('monster-none'),
									$elm$html$Html$Attributes$class(
									(!selectedLevel) ? 'selected' : ''),
									$author$project$HtmlEvents$onClickPreventDefault(
									A3($author$project$Creator$ChangeMonsterState, id, playerSize, 0))
								]),
							_List_fromArray(
								[
									$elm$html$Html$text('None')
								])),
							A2(
							$elm$html$Html$li,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('monster-normal'),
									$elm$html$Html$Attributes$class(
									(selectedLevel === 1) ? 'selected' : ''),
									$author$project$HtmlEvents$onClickPreventDefault(
									A3($author$project$Creator$ChangeMonsterState, id, playerSize, 1))
								]),
							_List_fromArray(
								[
									$elm$html$Html$text('Normal')
								])),
							A2(
							$elm$html$Html$li,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('monster-elite'),
									$elm$html$Html$Attributes$class(
									(selectedLevel === 2) ? 'selected' : ''),
									$author$project$HtmlEvents$onClickPreventDefault(
									A3($author$project$Creator$ChangeMonsterState, id, playerSize, 2))
								]),
							_List_fromArray(
								[
									$elm$html$Html$text('Elite')
								])),
							A2(
							$elm$html$Html$li,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('cancel cancel-menu'),
									$author$project$HtmlEvents$onClickPreventDefault(
									$author$project$Creator$ChangeContextMenuState(0))
								]),
							_List_fromArray(
								[
									$elm$html$Html$text('Cancel')
								]))
						]))
				]));
	});
var $elm$html$Html$nav = _VirtualDom_node('nav');
var $elm$html$Html$Attributes$style = $elm$virtual_dom$VirtualDom$style;
var $elm$core$String$toUpper = _String_toUpper;
var $author$project$Creator$getContextMenu = F6(
	function (state, _v0, _v1, rooms, overlays, monsters) {
		var x = _v0.a;
		var y = _v0.b;
		var absX = _v1.a;
		var absY = _v1.b;
		var monster = $elm$core$List$head(
			A2(
				$elm$core$List$filter,
				function (m) {
					return _Utils_eq(m.be, x) && _Utils_eq(m.bf, y);
				},
				monsters));
		var filteredRoom = A2(
			$elm$core$List$map,
			function (_v9) {
				var r = _v9.a;
				return r;
			},
			A2(
				$elm$core$List$filter,
				function (_v6) {
					var cells = _v6.b;
					var _v7 = A2(
						$elm$core$Dict$get,
						_Utils_Tuple2(x, y),
						cells);
					if (!_v7.$) {
						var _v8 = _v7.a;
						var p = _v8.b;
						return p;
					} else {
						return false;
					}
				},
				rooms));
		var filteredOverlays = A2(
			$elm$core$List$filter,
			function (o) {
				return A2(
					$elm$core$List$any,
					function (c) {
						return _Utils_eq(
							c,
							_Utils_Tuple2(x, y));
					},
					o.S);
			},
			overlays);
		var menuList = (state !== 1) ? _Utils_ap(
			function () {
				if (!monster.$) {
					var m = monster.a;
					var _v3 = m.m.m;
					if (!_v3.$) {
						return _List_fromArray(
							[
								A5($author$project$Creator$getMonsterLevelHtml, 2, state === 2, m.dM, 2, m.m.ag),
								A5($author$project$Creator$getMonsterLevelHtml, 3, state === 3, m.dF, 3, m.m.ag),
								A5($author$project$Creator$getMonsterLevelHtml, 4, state === 4, m.cP, 4, m.m.ag)
							]);
					} else {
						return _List_Nil;
					}
				} else {
					return _List_Nil;
				}
			}(),
			_Utils_ap(
				A2(
					$elm$core$List$map,
					function (o) {
						return A2(
							$elm$html$Html$li,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('rotate-overlay'),
									$author$project$HtmlEvents$onClickPreventDefault(
									$author$project$Creator$RotateOverlay(o.ag))
								]),
							_List_fromArray(
								[
									$elm$html$Html$text(
									'Rotate ' + $author$project$BoardOverlay$getOverlayLabel(o.bJ))
								]));
					},
					A2(
						$elm$core$List$filter,
						function (o) {
							var _v4 = o.bJ;
							switch (_v4.$) {
								case 6:
									return false;
								case 3:
									return false;
								case 5:
									return false;
								case 9:
									return false;
								default:
									return true;
							}
						},
						filteredOverlays)),
				_Utils_ap(
					A2(
						$elm$core$List$map,
						function (room) {
							var refStr = A2(
								$elm$core$Maybe$withDefault,
								'',
								$author$project$BoardMapTile$refToString(room));
							var restChars = A3(
								$elm$core$String$slice,
								1,
								$elm$core$String$length(refStr),
								refStr);
							var firstChar = $elm$core$String$toUpper(
								A3($elm$core$String$slice, 0, 1, refStr));
							return A2(
								$elm$html$Html$li,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('rotate-map-tile'),
										$author$project$HtmlEvents$onClickPreventDefault(
										$author$project$Creator$RotateRoom(room))
									]),
								_List_fromArray(
									[
										$elm$html$Html$text('Rotate ' + (firstChar + restChars))
									]));
						},
						filteredRoom),
					_Utils_ap(
						function () {
							if (!monster.$) {
								var m = monster.a;
								var monsterName = A2(
									$elm$core$String$join,
									' ',
									A2(
										$elm$core$List$map,
										function (s) {
											return _Utils_ap(
												$elm$core$String$toUpper(
													A3($elm$core$String$slice, 0, 1, s)),
												A3(
													$elm$core$String$slice,
													1,
													$elm$core$String$length(s),
													s));
										},
										A2(
											$elm$core$String$split,
											'-',
											A2(
												$elm$core$Maybe$withDefault,
												'',
												$author$project$Monster$monsterTypeToString(m.m.m)))));
								return _List_fromArray(
									[
										A2(
										$elm$html$Html$li,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('remove-monster'),
												$author$project$HtmlEvents$onClickPreventDefault(
												$author$project$Creator$RemoveMonster(m.m.ag))
											]),
										_List_fromArray(
											[
												$elm$html$Html$text('Remove ' + monsterName)
											]))
									]);
							} else {
								return _List_Nil;
							}
						}(),
						_Utils_ap(
							A2(
								$elm$core$List$map,
								function (o) {
									return A2(
										$elm$html$Html$li,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('remove-overlay'),
												$author$project$HtmlEvents$onClickPreventDefault(
												$author$project$Creator$RemoveOverlay(o.ag))
											]),
										_List_fromArray(
											[
												$elm$html$Html$text(
												'Remove ' + $author$project$BoardOverlay$getOverlayLabel(o.bJ))
											]));
								},
								filteredOverlays),
							A2(
								$elm$core$List$map,
								function (room) {
									var refStr = A2(
										$elm$core$Maybe$withDefault,
										'',
										$author$project$BoardMapTile$refToString(room));
									var restChars = A3(
										$elm$core$String$slice,
										1,
										$elm$core$String$length(refStr),
										refStr);
									var firstChar = $elm$core$String$toUpper(
										A3($elm$core$String$slice, 0, 1, refStr));
									return A2(
										$elm$html$Html$li,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('remove-map-tile'),
												$author$project$HtmlEvents$onClickPreventDefault(
												$author$project$Creator$RemoveRoom(room))
											]),
										_List_fromArray(
											[
												$elm$html$Html$text('Remove ' + (firstChar + restChars))
											]));
								},
								filteredRoom)))))) : _List_Nil;
		var isOpen = (state !== 1) && ($elm$core$List$length(menuList) > 0);
		return A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('context-menu'),
					$elm$html$Html$Attributes$class(
					isOpen ? 'open' : ''),
					$elm$html$Html$Attributes$class(
					(!(!state)) ? 'sub-menu-open' : ''),
					A2(
					$elm$html$Html$Attributes$style,
					'top',
					$elm$core$String$fromInt(absY) + 'px'),
					A2(
					$elm$html$Html$Attributes$style,
					'left',
					$elm$core$String$fromInt(absX) + 'px')
				]),
			_List_fromArray(
				[
					A2(
					$elm$html$Html$nav,
					_List_Nil,
					_List_fromArray(
						[
							A2(
							$elm$html$Html$ul,
							_List_Nil,
							isOpen ? _Utils_ap(
								menuList,
								_List_fromArray(
									[
										A2(
										$elm$html$Html$li,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('cancel-menu cancel'),
												$author$project$HtmlEvents$onClickPreventDefault(
												$author$project$Creator$ChangeContextMenuState(1))
											]),
										_List_fromArray(
											[
												$elm$html$Html$text('Cancel')
											]))
									])) : _List_Nil)
						]))
				]));
	});
var $author$project$Creator$HideError = {$: 27};
var $elm$html$Html$a = _VirtualDom_node('a');
var $elm$virtual_dom$VirtualDom$Normal = function (a) {
	return {$: 0, a: a};
};
var $elm$html$Html$Events$on = F2(
	function (event, decoder) {
		return A2(
			$elm$virtual_dom$VirtualDom$on,
			event,
			$elm$virtual_dom$VirtualDom$Normal(decoder));
	});
var $elm$html$Html$Events$onClick = function (msg) {
	return A2(
		$elm$html$Html$Events$on,
		'click',
		$elm$json$Json$Decode$succeed(msg));
};
var $author$project$Creator$getErrorStatusHtml = F2(
	function (message, showMessage) {
		return A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class(
					'errorStatus' + (showMessage ? ' show' : '')),
					A2(
					$elm$html$Html$Attributes$attribute,
					'aria-hidden',
					showMessage ? 'false' : 'true')
				]),
			_List_fromArray(
				[
					A2(
					$elm$html$Html$span,
					_List_Nil,
					_List_fromArray(
						[
							$elm$html$Html$text(message)
						])),
					A2(
					$elm$html$Html$a,
					_List_fromArray(
						[
							$elm$html$Html$Events$onClick($author$project$Creator$HideError)
						]),
					_List_fromArray(
						[
							$elm$html$Html$text('Close')
						]))
				]));
	});
var $elm$html$Html$footer = _VirtualDom_node('footer');
var $elm$html$Html$Attributes$href = function (url) {
	return A2(
		$elm$html$Html$Attributes$stringProperty,
		'href',
		_VirtualDom_noJavaScriptUri(url));
};
var $elm$html$Html$iframe = _VirtualDom_node('iframe');
var $elm$html$Html$Attributes$src = function (url) {
	return A2(
		$elm$html$Html$Attributes$stringProperty,
		'src',
		_VirtualDom_noJavaScriptOrHtmlUri(url));
};
var $elm$html$Html$Attributes$target = $elm$html$Html$Attributes$stringProperty('target');
var $elm$html$Html$Attributes$title = $elm$html$Html$Attributes$stringProperty('title');
var $author$project$BoardHtml$getFooterHtml = function (v) {
	return A2(
		$elm$html$Html$footer,
		_List_Nil,
		_List_fromArray(
			[
				A2(
				$elm$html$Html$div,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('credits')
					]),
				_List_fromArray(
					[
						A2(
						$elm$html$Html$span,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('gloomCopy')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text('Gloomhaven and all related properties and images are owned by '),
								A2(
								$elm$html$Html$a,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$href('http://www.cephalofair.com/')
									]),
								_List_fromArray(
									[
										$elm$html$Html$text('Cephalofair Games')
									]))
							])),
						A2(
						$elm$html$Html$span,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('any2CardCopy')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text('Additional card scans courtesy of '),
								A2(
								$elm$html$Html$a,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$href('https://github.com/any2cards/gloomhaven')
									]),
								_List_fromArray(
									[
										$elm$html$Html$text('Any2Cards')
									]))
							]))
					])),
				A2(
				$elm$html$Html$div,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('pkg')
					]),
				_List_fromArray(
					[
						A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('copy-wrapper')
							]),
						_List_fromArray(
							[
								A2(
								$elm$html$Html$span,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('pkgCopy')
									]),
								_List_fromArray(
									[
										$elm$html$Html$text('Developed by '),
										A2(
										$elm$html$Html$a,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$href('https://purplekingdomgames.com/')
											]),
										_List_fromArray(
											[
												$elm$html$Html$text('Purple Kingdom Games')
											]))
									])),
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('sponsor')
									]),
								_List_fromArray(
									[
										A2(
										$elm$html$Html$iframe,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('sponsor-button'),
												$elm$html$Html$Attributes$src('https://github.com/sponsors/PurpleKingdomGames/button'),
												$elm$html$Html$Attributes$title('Sponsor PurpleKingdomGames'),
												A2($elm$html$Html$Attributes$attribute, 'aria-hidden', 'true')
											]),
										_List_Nil)
									]))
							])),
						A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('version')
							]),
						_List_fromArray(
							[
								A2(
								$elm$html$Html$a,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$target('_new'),
										$elm$html$Html$Attributes$href('https://github.com/PurpleKingdomGames/virtual-gloomhaven-board/issues/new/choose')
									]),
								_List_fromArray(
									[
										$elm$html$Html$text('Report a bug')
									])),
								A2(
								$elm$html$Html$span,
								_List_Nil,
								_List_fromArray(
									[
										$elm$html$Html$text('Version ' + v)
									]))
							]))
					]))
			]));
};
var $author$project$Creator$ToggleMenu = {$: 9};
var $author$project$Creator$ConfirmCreateNew = {$: 20};
var $author$project$Creator$ExportFile = {$: 22};
var $author$project$Creator$LoadFile = {$: 23};
var $visotype$elm_dom$Dom$addAction = function (_v0) {
	var event = _v0.a;
	var msg = _v0.b;
	var handler = A2($elm$core$Basics$composeR, $elm$json$Json$Decode$succeed, $elm$virtual_dom$VirtualDom$Normal);
	return $visotype$elm_dom$Dom$Internal$modify(
		function (n) {
			return _Utils_update(
				n,
				{
					b: A2(
						$elm$core$List$append,
						n.b,
						_List_fromArray(
							[
								_Utils_Tuple2(
								event,
								handler(msg))
							]))
				});
		});
};
var $elm$html$Html$Attributes$tabindex = function (n) {
	return A2(
		_VirtualDom_attribute,
		'tabIndex',
		$elm$core$String$fromInt(n));
};
var $author$project$Creator$getMenuHtml = function (menuOpen) {
	return $visotype$elm_dom$Dom$render(
		A2(
			$visotype$elm_dom$Dom$appendChild,
			A2(
				$visotype$elm_dom$Dom$appendChild,
				A2(
					$visotype$elm_dom$Dom$appendChild,
					A2(
						$visotype$elm_dom$Dom$appendText,
						'Donate',
						A2(
							$visotype$elm_dom$Dom$addAttribute,
							$elm$html$Html$Attributes$target('_new'),
							A2(
								$visotype$elm_dom$Dom$addAttribute,
								$elm$html$Html$Attributes$href('https://github.com/sponsors/PurpleKingdomGames?o=esb'),
								$visotype$elm_dom$Dom$element('a')))),
					A2(
						$visotype$elm_dom$Dom$addAttribute,
						$elm$html$Html$Attributes$tabindex(0),
						A2(
							$visotype$elm_dom$Dom$addAttribute,
							A2($elm$html$Html$Attributes$attribute, 'role', 'menuitem'),
							$visotype$elm_dom$Dom$element('li')))),
				A2(
					$visotype$elm_dom$Dom$appendChild,
					A2(
						$visotype$elm_dom$Dom$appendText,
						'Import',
						A2(
							$visotype$elm_dom$Dom$addClass,
							'section-end',
							A2(
								$visotype$elm_dom$Dom$addAction,
								_Utils_Tuple2('click', $author$project$Creator$LoadFile),
								A2(
									$visotype$elm_dom$Dom$addAttribute,
									$elm$html$Html$Attributes$tabindex(0),
									A2(
										$visotype$elm_dom$Dom$addAttribute,
										A2($elm$html$Html$Attributes$attribute, 'role', 'menuitem'),
										$visotype$elm_dom$Dom$element('li')))))),
					A2(
						$visotype$elm_dom$Dom$appendChild,
						A2(
							$visotype$elm_dom$Dom$appendText,
							'Export',
							A2(
								$visotype$elm_dom$Dom$addAction,
								_Utils_Tuple2('click', $author$project$Creator$ExportFile),
								A2(
									$visotype$elm_dom$Dom$addAttribute,
									$elm$html$Html$Attributes$tabindex(0),
									A2(
										$visotype$elm_dom$Dom$addAttribute,
										A2($elm$html$Html$Attributes$attribute, 'role', 'menuitem'),
										$visotype$elm_dom$Dom$element('li'))))),
						A2(
							$visotype$elm_dom$Dom$appendChild,
							A2(
								$visotype$elm_dom$Dom$appendText,
								'Create New',
								A2(
									$visotype$elm_dom$Dom$addClass,
									'section-end',
									A2(
										$visotype$elm_dom$Dom$addAction,
										_Utils_Tuple2('click', $author$project$Creator$ConfirmCreateNew),
										A2(
											$visotype$elm_dom$Dom$addAttribute,
											$elm$html$Html$Attributes$tabindex(0),
											A2(
												$visotype$elm_dom$Dom$addAttribute,
												A2($elm$html$Html$Attributes$attribute, 'role', 'menuitem'),
												$visotype$elm_dom$Dom$element('li')))))),
							A2(
								$visotype$elm_dom$Dom$addAttribute,
								A2($elm$html$Html$Attributes$attribute, 'role', 'menu'),
								$visotype$elm_dom$Dom$element('ul')))))),
			A2(
				$visotype$elm_dom$Dom$addAttribute,
				A2(
					$elm$html$Html$Attributes$attribute,
					'aria-hidden',
					menuOpen ? 'false' : 'true'),
				$visotype$elm_dom$Dom$element('nav'))));
};
var $elm$virtual_dom$VirtualDom$lazy = _VirtualDom_lazy;
var $elm$html$Html$Lazy$lazy = $elm$virtual_dom$VirtualDom$lazy;
var $author$project$Creator$getMenuToggleHtml = function (model) {
	return A2(
		$elm$html$Html$div,
		_List_fromArray(
			[
				$elm$html$Html$Attributes$class(
				'menu' + (model.M ? ' show' : '')),
				$elm$html$Html$Events$onClick($author$project$Creator$ToggleMenu),
				$elm$html$Html$Attributes$tabindex(0),
				A2($elm$html$Html$Attributes$attribute, 'aria-label', 'Toggle Menu'),
				A2($elm$html$Html$Attributes$attribute, 'aria-keyshortcuts', 'm'),
				A2($elm$html$Html$Attributes$attribute, 'role', 'button'),
				A2(
				$elm$html$Html$Attributes$attribute,
				'aria-pressed',
				model.M ? 'true' : 'false')
			]),
		_List_fromArray(
			[
				A2($elm$html$Html$Lazy$lazy, $author$project$Creator$getMenuHtml, model.M)
			]));
};
var $author$project$Creator$ChangeScenarioTitle = function (a) {
	return {$: 26, a: a};
};
var $elm$html$Html$header = _VirtualDom_node('header');
var $elm$html$Html$input = _VirtualDom_node('input');
var $elm$html$Html$Attributes$maxlength = function (n) {
	return A2(
		_VirtualDom_attribute,
		'maxlength',
		$elm$core$String$fromInt(n));
};
var $elm$html$Html$Events$alwaysStop = function (x) {
	return _Utils_Tuple2(x, true);
};
var $elm$virtual_dom$VirtualDom$MayStopPropagation = function (a) {
	return {$: 1, a: a};
};
var $elm$html$Html$Events$stopPropagationOn = F2(
	function (event, decoder) {
		return A2(
			$elm$virtual_dom$VirtualDom$on,
			event,
			$elm$virtual_dom$VirtualDom$MayStopPropagation(decoder));
	});
var $elm$json$Json$Decode$at = F2(
	function (fields, decoder) {
		return A3($elm$core$List$foldr, $elm$json$Json$Decode$field, decoder, fields);
	});
var $elm$html$Html$Events$targetValue = A2(
	$elm$json$Json$Decode$at,
	_List_fromArray(
		['target', 'value']),
	$elm$json$Json$Decode$string);
var $elm$html$Html$Events$onInput = function (tagger) {
	return A2(
		$elm$html$Html$Events$stopPropagationOn,
		'input',
		A2(
			$elm$json$Json$Decode$map,
			$elm$html$Html$Events$alwaysStop,
			A2($elm$json$Json$Decode$map, tagger, $elm$html$Html$Events$targetValue)));
};
var $elm$html$Html$Attributes$placeholder = $elm$html$Html$Attributes$stringProperty('placeholder');
var $elm$html$Html$Attributes$type_ = $elm$html$Html$Attributes$stringProperty('type');
var $elm$html$Html$Attributes$value = $elm$html$Html$Attributes$stringProperty('value');
var $author$project$Creator$getScenarioTitleHtml = function (scenarioTitle) {
	return A2(
		$elm$html$Html$header,
		_List_fromArray(
			[
				A2($elm$html$Html$Attributes$attribute, 'aria-label', 'Scenario Title')
			]),
		_List_fromArray(
			[
				A2(
				$elm$html$Html$span,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('title')
					]),
				_List_fromArray(
					[
						A2(
						$elm$html$Html$input,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$type_('text'),
								$elm$html$Html$Attributes$value(scenarioTitle),
								$elm$html$Html$Events$onInput($author$project$Creator$ChangeScenarioTitle),
								$elm$html$Html$Attributes$placeholder('Enter Scenario Title'),
								$elm$html$Html$Attributes$maxlength(30)
							]),
						_List_Nil)
					]))
			]));
};
var $author$project$Creator$getHeaderHtml = function (model) {
	return A2(
		$elm$html$Html$div,
		_List_fromArray(
			[
				$elm$html$Html$Attributes$class('header')
			]),
		_List_fromArray(
			[
				$author$project$Creator$getMenuToggleHtml(model),
				A2($elm$html$Html$Lazy$lazy, $author$project$Creator$getScenarioTitleHtml, model.a.bZ)
			]));
};
var $elm$html$Html$img = _VirtualDom_node('img');
var $author$project$BoardHtml$getSingleMapTileHtml = F5(
	function (isVisible, ref, turns, x, y) {
		var yPx = y * 67;
		var xPx = (x * 76) + (((y & 1) === 1) ? 38 : 0);
		return A2(
			$elm$html$Html$div,
			_List_Nil,
			_List_fromArray(
				[
					A2(
					$elm$html$Html$div,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('mapTile'),
							$elm$html$Html$Attributes$class(
							'rotate-' + $elm$core$String$fromInt(turns)),
							$elm$html$Html$Attributes$class(
							isVisible ? 'visible' : 'hidden'),
							A2(
							$elm$html$Html$Attributes$style,
							'top',
							$elm$core$String$fromInt(yPx) + 'px'),
							A2(
							$elm$html$Html$Attributes$style,
							'left',
							$elm$core$String$fromInt(xPx) + 'px')
						]),
					_List_fromArray(
						[
							A2(
							$elm$html$Html$img,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$src('/img/map-tiles/' + (ref + '.png')),
									$elm$html$Html$Attributes$class('ref-' + ref),
									$elm$html$Html$Attributes$alt('Map tile ' + ref),
									A2(
									$elm$html$Html$Attributes$attribute,
									'aria-hidden',
									isVisible ? 'false' : 'true')
								]),
							_List_Nil)
						])),
					A2(
					$elm$html$Html$div,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('mapTile outline'),
							$elm$html$Html$Attributes$class(
							'rotate-' + $elm$core$String$fromInt(turns)),
							$elm$html$Html$Attributes$class(
							isVisible ? 'hidden' : 'visible'),
							A2(
							$elm$html$Html$Attributes$style,
							'top',
							$elm$core$String$fromInt(yPx) + 'px'),
							A2(
							$elm$html$Html$Attributes$style,
							'left',
							$elm$core$String$fromInt(xPx) + 'px'),
							A2(
							$elm$html$Html$Attributes$attribute,
							'aria-hidden',
							isVisible ? 'true' : 'false')
						]),
					function () {
						var _v0 = $author$project$BoardMapTile$stringToRef(ref);
						if (_v0.$ === 1) {
							return _List_Nil;
						} else {
							if (_v0.a === 62) {
								var _v1 = _v0.a;
								return _List_Nil;
							} else {
								var r = _v0.a;
								var overlayPrefix = function () {
									switch (r) {
										case 42:
											return 'ja';
										case 46:
											return 'ja';
										case 43:
											return 'jb';
										case 44:
											return 'jb';
										case 45:
											return 'jb';
										case 47:
											return 'jb';
										default:
											return A2($elm$core$String$left, 1, ref);
									}
								}();
								return _List_fromArray(
									[
										A2(
										$elm$html$Html$img,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$src('/img/map-tiles/' + (overlayPrefix + '-outline.png')),
												$elm$html$Html$Attributes$class('ref-' + ref),
												$elm$html$Html$Attributes$alt('The outline of map tile ' + ref)
											]),
										_List_Nil)
									]);
							}
						}
					}())
				]));
	});
var $elm$virtual_dom$VirtualDom$lazy5 = _VirtualDom_lazy5;
var $elm$html$Html$Lazy$lazy5 = $elm$virtual_dom$VirtualDom$lazy5;
var $author$project$BoardHtml$getMapTileHtml = F5(
	function (visibleRooms, roomData, currentDraggable, draggableX, draggableY) {
		return A3(
			$elm$html$Html$Keyed$node,
			'div',
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('mapTiles')
				]),
			A2(
				$elm$core$List$map,
				function (r) {
					var ref = A2(
						$elm$core$Maybe$withDefault,
						'',
						$author$project$BoardMapTile$refToString(r.bJ));
					var isVisible = A2($elm$core$List$member, r.bJ, visibleRooms);
					var _v0 = _Utils_eq(ref, currentDraggable) ? _Utils_Tuple2(draggableX, draggableY) : r.dj;
					var x = _v0.a;
					var y = _v0.b;
					return _Utils_Tuple2(
						ref,
						A6($elm$html$Html$Lazy$lazy5, $author$project$BoardHtml$getSingleMapTileHtml, isVisible, ref, r.dL, x, y));
				},
				A2(
					$elm_community$list_extra$List$Extra$uniqueBy,
					function (d) {
						return A2(
							$elm$core$Maybe$withDefault,
							'',
							$author$project$BoardMapTile$refToString(d.bJ));
					},
					roomData)));
	});
var $author$project$BoardHtml$getAllMapTileHtml = F4(
	function (roomData, currentDraggable, draggableX, draggableY) {
		var allRooms = function () {
			if (A2(
				$elm$core$List$member,
				currentDraggable,
				A2(
					$elm$core$List$map,
					function (r) {
						return A2(
							$elm$core$Maybe$withDefault,
							'',
							$author$project$BoardMapTile$refToString(r.bJ));
					},
					roomData))) {
				return roomData;
			} else {
				var _v0 = $author$project$BoardMapTile$stringToRef(currentDraggable);
				if (!_v0.$) {
					var r = _v0.a;
					return A2(
						$elm$core$List$cons,
						A3(
							$author$project$Game$RoomData,
							r,
							_Utils_Tuple2(draggableX, draggableY),
							0),
						roomData);
				} else {
					return roomData;
				}
			}
		}();
		return A5(
			$author$project$BoardHtml$getMapTileHtml,
			A2(
				$elm$core$List$map,
				function (d) {
					return d.bJ;
				},
				allRooms),
			allRooms,
			currentDraggable,
			draggableX,
			draggableY);
	});
var $author$project$Creator$getLazyMapTileHtml = F4(
	function (r, c, x, y) {
		var roomData = A2(
			$elm$core$List$map,
			function (m) {
				return m.a$;
			},
			r);
		return A4($author$project$BoardHtml$getAllMapTileHtml, roomData, c, x, y);
	});
var $author$project$Creator$ChangeSideMenu = function (a) {
	return {$: 10, a: a};
};
var $elm$core$Dict$values = function (dict) {
	return A3(
		$elm$core$Dict$foldr,
		F3(
			function (key, value, valueList) {
				return A2($elm$core$List$cons, value, valueList);
			}),
		_List_Nil,
		dict);
};
var $author$project$BoardMapTile$getAllRefs = A2(
	$elm$core$List$filter,
	function (r) {
		return r !== 62;
	},
	$elm$core$Dict$values($author$project$BoardMapTile$boardRefDict));
var $elm$virtual_dom$VirtualDom$lazy2 = _VirtualDom_lazy2;
var $elm$html$Html$Lazy$lazy2 = $elm$virtual_dom$VirtualDom$lazy2;
var $author$project$Creator$lazyMapTileListHtml = F2(
	function (ref, currentDraggable) {
		var r = A2(
			$elm$core$Maybe$withDefault,
			62,
			$author$project$BoardMapTile$stringToRef(ref));
		return $visotype$elm_dom$Dom$render(
			A2(
				$visotype$elm_dom$Dom$appendChild,
				A4(
					$author$project$BoardHtml$makeDraggable,
					$author$project$AppStorage$RoomType(
						A3(
							$author$project$Game$RoomData,
							r,
							_Utils_Tuple2(0, 0),
							0)),
					$elm$core$Maybe$Nothing,
					$author$project$Creator$dragEvents,
					A2(
						$visotype$elm_dom$Dom$addAttributeList,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$src('/img/map-tiles/' + (ref + '.png')),
								$elm$html$Html$Attributes$alt('Map tile ' + ref)
							]),
						$visotype$elm_dom$Dom$element('img'))),
				A3(
					$visotype$elm_dom$Dom$addClassConditional,
					'dragging',
					_Utils_eq(ref, currentDraggable),
					A2(
						$visotype$elm_dom$Dom$addClass,
						'ref-' + ref,
						$visotype$elm_dom$Dom$element('li')))));
	});
var $elm$html$Html$section = _VirtualDom_node('section');
var $author$project$Creator$getMapTileListHtml = F3(
	function (mapTiles, currentDraggable, sideMenu) {
		var htmlClass = (!sideMenu) ? 'active' : '';
		var currentRefs = A2(
			$elm$core$List$map,
			function (r) {
				return r.a$.bJ;
			},
			mapTiles);
		return A2(
			$elm$html$Html$section,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class(htmlClass),
					$elm$html$Html$Events$onClick(
					$author$project$Creator$ChangeSideMenu(0))
				]),
			_List_fromArray(
				[
					A2(
					$elm$html$Html$header,
					_List_Nil,
					_List_fromArray(
						[
							$elm$html$Html$text('Tiles')
						])),
					A3(
					$elm$html$Html$Keyed$node,
					'ul',
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('map-tiles')
						]),
					A2(
						$elm$core$List$map,
						function (r) {
							var ref = A2(
								$elm$core$Maybe$withDefault,
								'',
								$author$project$BoardMapTile$refToString(r));
							return _Utils_Tuple2(
								'new-tile-' + ref,
								A3($elm$html$Html$Lazy$lazy2, $author$project$Creator$lazyMapTileListHtml, ref, currentDraggable));
						},
						A2(
							$elm$core$List$filter,
							function (r) {
								return (r !== 44) && ((r !== 45) && (!A2($elm$core$List$member, r, currentRefs)));
							},
							$author$project$BoardMapTile$getAllRefs)))
				]));
	});
var $elm$virtual_dom$VirtualDom$lazy3 = _VirtualDom_lazy3;
var $elm$html$Html$Lazy$lazy3 = $elm$virtual_dom$VirtualDom$lazy3;
var $author$project$BoardOverlay$getBoardOverlayType = function (overlayName) {
	return A2($elm$core$Dict$get, overlayName, $author$project$BoardOverlay$overlayDictionary);
};
var $author$project$Creator$lazyBoardOverlayListHtml = F3(
	function (id, overlayStr, isDragging) {
		var _v0 = $author$project$BoardOverlay$getBoardOverlayType(overlayStr);
		if (!_v0.$) {
			var overlay = _v0.a;
			var twoCells = _List_fromArray(
				[
					_Utils_Tuple2(0, 0),
					_Utils_Tuple2(1, 0)
				]);
			var threeCells = _List_fromArray(
				[
					_Utils_Tuple2(0, 0),
					_Utils_Tuple2(1, 0),
					_Utils_Tuple2(0, -1)
				]);
			var cells = function () {
				_v2$14:
				while (true) {
					switch (overlay.$) {
						case 0:
							if (!overlay.a) {
								var _v3 = overlay.a;
								return twoCells;
							} else {
								break _v2$14;
							}
						case 4:
							switch (overlay.a) {
								case 2:
									var _v4 = overlay.a;
									return twoCells;
								case 4:
									var _v5 = overlay.a;
									return twoCells;
								case 5:
									var _v6 = overlay.a;
									return threeCells;
								case 10:
									var _v7 = overlay.a;
									return twoCells;
								case 16:
									var _v8 = overlay.a;
									return twoCells;
								case 17:
									var _v9 = overlay.a;
									return twoCells;
								case 20:
									var _v10 = overlay.a;
									return twoCells;
								case 22:
									var _v11 = overlay.a;
									return threeCells;
								case 23:
									var _v12 = overlay.a;
									return twoCells;
								default:
									break _v2$14;
							}
						case 10:
							switch (overlay.a) {
								case 0:
									var _v13 = overlay.a;
									return threeCells;
								case 1:
									var _v14 = overlay.a;
									return twoCells;
								case 2:
									var _v15 = overlay.a;
									return twoCells;
								case 3:
									var _v16 = overlay.a;
									return twoCells;
								default:
									break _v2$14;
							}
						default:
							break _v2$14;
					}
				}
				return _List_fromArray(
					[
						_Utils_Tuple2(0, 0)
					]);
			}();
			var boardOverlayModel = {S: cells, aw: 0, ag: id, bJ: overlay};
			return $visotype$elm_dom$Dom$render(
				A4(
					$author$project$BoardHtml$makeDraggable,
					A2($author$project$AppStorage$OverlayType, boardOverlayModel, $elm$core$Maybe$Nothing),
					$elm$core$Maybe$Nothing,
					$author$project$Creator$dragEvents,
					A2(
						$visotype$elm_dom$Dom$appendChildList,
						A2(
							$elm$core$List$map,
							function (c) {
								if (overlay.$ === 9) {
									var val = overlay.a;
									return A2(
										$visotype$elm_dom$Dom$appendChild,
										A2(
											$visotype$elm_dom$Dom$appendText,
											val,
											$visotype$elm_dom$Dom$element('span')),
										A2(
											$visotype$elm_dom$Dom$addClass,
											'token',
											A2(
												$visotype$elm_dom$Dom$addClass,
												'overlay',
												$visotype$elm_dom$Dom$element('div'))));
								} else {
									return A2(
										$visotype$elm_dom$Dom$addAttribute,
										A2($elm$html$Html$Attributes$attribute, 'draggable', 'false'),
										A2(
											$visotype$elm_dom$Dom$addAttribute,
											A2(
												$elm$html$Html$Attributes$attribute,
												'src',
												A2(
													$author$project$BoardHtml$getOverlayImageName,
													boardOverlayModel,
													$elm$core$Maybe$Just(c))),
											A2(
												$visotype$elm_dom$Dom$addAttribute,
												$elm$html$Html$Attributes$alt(
													$author$project$BoardOverlay$getOverlayLabel(overlay)),
												$visotype$elm_dom$Dom$element('img'))));
								}
							},
							cells),
						A3(
							$visotype$elm_dom$Dom$addClassConditional,
							'dragging',
							isDragging,
							A2(
								$visotype$elm_dom$Dom$addClass,
								'size-' + $elm$core$String$fromInt(
									$elm$core$List$length(cells)),
								$visotype$elm_dom$Dom$element('li'))))));
		} else {
			return A2($elm$html$Html$li, _List_Nil, _List_Nil);
		}
	});
var $author$project$Creator$getOverlayListHtml = F5(
	function (id, overlays, label, currentDraggable, active) {
		var menuType = function () {
			var _v0 = $elm$core$String$toLower(label);
			switch (_v0) {
				case 'doors':
					return 1;
				case 'obstacles':
					return 2;
				default:
					return 3;
			}
		}();
		var htmlClass = active ? 'active' : '';
		return A2(
			$elm$html$Html$section,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class(htmlClass),
					$elm$html$Html$Events$onClick(
					$author$project$Creator$ChangeSideMenu(menuType))
				]),
			_List_fromArray(
				[
					A2(
					$elm$html$Html$header,
					_List_Nil,
					_List_fromArray(
						[
							$elm$html$Html$text(label)
						])),
					A3(
					$elm$html$Html$Keyed$node,
					'ul',
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('board-overlays')
						]),
					A2(
						$elm$core$List$map,
						function (k) {
							var isDragging = _Utils_eq(currentDraggable, k);
							return _Utils_Tuple2(
								'new-overlay-' + k,
								A4($elm$html$Html$Lazy$lazy3, $author$project$Creator$lazyBoardOverlayListHtml, id, k, isDragging));
						},
						overlays))
				]));
	});
var $author$project$Monster$getAllBosses = $author$project$Monster$bossDict;
var $author$project$Creator$getScenarioBossListHtml = F3(
	function (maxId, currentDraggable, active) {
		var htmlClass = active ? 'active' : '';
		return A2(
			$elm$html$Html$section,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class(htmlClass),
					$elm$html$Html$Events$onClick(
					$author$project$Creator$ChangeSideMenu(5))
				]),
			_List_fromArray(
				[
					A2(
					$elm$html$Html$header,
					_List_Nil,
					_List_fromArray(
						[
							$elm$html$Html$text('Bosses')
						])),
					A3(
					$elm$html$Html$Keyed$node,
					'ul',
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('monsters')
						]),
					A2(
						$elm$core$List$map,
						function (_v0) {
							var k = _v0.a;
							var v = _v0.b;
							var monster = {
								aY: $elm$core$Maybe$Nothing,
								l: $author$project$Creator$dragEvents,
								L: _Utils_eq(currentDraggable, k),
								m: A6(
									$author$project$Scenario$ScenarioMonster,
									{
										ag: maxId,
										bj: 0,
										m: $author$project$Monster$BossType(v),
										bz: false,
										cg: false
									},
									0,
									0,
									1,
									1,
									1)
							};
							var _v1 = A2($author$project$BoardHtml$scenarioMonsterToHtml, true, monster);
							var node = _v1.b;
							return _Utils_Tuple2(
								'new-monster-' + k,
								A2(
									$elm$html$Html$li,
									_List_Nil,
									_List_fromArray(
										[
											$visotype$elm_dom$Dom$render(node)
										])));
						},
						$elm$core$Dict$toList($author$project$Monster$getAllBosses)))
				]));
	});
var $author$project$Monster$getAllMonsters = $author$project$Monster$normalDict;
var $author$project$Creator$getScenarioMonsterListHtml = F3(
	function (maxId, currentDraggable, active) {
		var htmlClass = active ? 'active' : '';
		return A2(
			$elm$html$Html$section,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class(htmlClass),
					$elm$html$Html$Events$onClick(
					$author$project$Creator$ChangeSideMenu(4))
				]),
			_List_fromArray(
				[
					A2(
					$elm$html$Html$header,
					_List_Nil,
					_List_fromArray(
						[
							$elm$html$Html$text('Monsters')
						])),
					A3(
					$elm$html$Html$Keyed$node,
					'ul',
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('monsters')
						]),
					A2(
						$elm$core$List$map,
						function (_v0) {
							var k = _v0.a;
							var v = _v0.b;
							var monster = {
								aY: $elm$core$Maybe$Nothing,
								l: $author$project$Creator$dragEvents,
								L: _Utils_eq(currentDraggable, k),
								m: A6(
									$author$project$Scenario$ScenarioMonster,
									{
										ag: maxId,
										bj: 0,
										m: $author$project$Monster$NormalType(v),
										bz: false,
										cg: false
									},
									0,
									0,
									1,
									1,
									1)
							};
							var _v1 = A2($author$project$BoardHtml$scenarioMonsterToHtml, true, monster);
							var node = _v1.b;
							return _Utils_Tuple2(
								'new-monster-' + k,
								A2(
									$elm$html$Html$li,
									_List_Nil,
									_List_fromArray(
										[
											$visotype$elm_dom$Dom$render(node)
										])));
						},
						$elm$core$Dict$toList($author$project$Monster$getAllMonsters)))
				]));
	});
var $elm$html$Html$Attributes$id = $elm$html$Html$Attributes$stringProperty('id');
var $elm$virtual_dom$VirtualDom$lazy4 = _VirtualDom_lazy4;
var $elm$html$Html$Lazy$lazy4 = $elm$virtual_dom$VirtualDom$lazy4;
var $elm$virtual_dom$VirtualDom$lazy6 = _VirtualDom_lazy6;
var $elm$html$Html$Lazy$lazy6 = $elm$virtual_dom$VirtualDom$lazy6;
var $mpizenberg$elm_pointer_events$Html$Events$Extra$Touch$onCancel = A2($mpizenberg$elm_pointer_events$Html$Events$Extra$Touch$onWithOptions, 'touchcancel', $mpizenberg$elm_pointer_events$Html$Events$Extra$Touch$defaultOptions);
var $elm$core$List$repeatHelp = F3(
	function (result, n, value) {
		repeatHelp:
		while (true) {
			if (n <= 0) {
				return result;
			} else {
				var $temp$result = A2($elm$core$List$cons, value, result),
					$temp$n = n - 1,
					$temp$value = value;
				result = $temp$result;
				n = $temp$n;
				value = $temp$value;
				continue repeatHelp;
			}
		}
	});
var $elm$core$List$repeat = F2(
	function (n, value) {
		return A3($elm$core$List$repeatHelp, _List_Nil, n, value);
	});
var $author$project$Creator$view = function (model) {
	return A3(
		$elm$html$Html$Keyed$node,
		'div',
		_List_fromArray(
			[
				$elm$html$Html$Attributes$class('content scenario-creator'),
				$elm$html$Html$Attributes$id('content'),
				$mpizenberg$elm_pointer_events$Html$Events$Extra$Touch$onCancel(
				function (_v0) {
					return $author$project$Creator$TouchCanceled;
				}),
				$elm$html$Html$Events$onClick(
				$author$project$Creator$ChangeContextMenuState(1))
			]),
		_List_fromArray(
			[
				_Utils_Tuple2(
				'head',
				$author$project$Creator$getHeaderHtml(model)),
				_Utils_Tuple2(
				'main',
				A2(
					$elm$html$Html$div,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('main')
						]),
					_List_fromArray(
						[
							A2(
							$elm$html$Html$div,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('page-shadow')
								]),
							_List_Nil),
							A3(
							$elm$html$Html$Keyed$node,
							'div',
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('action-list')
								]),
							function () {
								var roomDragabble = function () {
									var _v8 = model.a_;
									if (!_v8.$) {
										var m = _v8.a;
										var _v9 = m.bJ;
										if (_v9.$ === 2) {
											var r = _v9.a;
											var _v10 = m.aY;
											if (!_v10.$) {
												return '';
											} else {
												return A2(
													$elm$core$Maybe$withDefault,
													'',
													$author$project$BoardMapTile$refToString(r.bJ));
											}
										} else {
											return '';
										}
									} else {
										return '';
									}
								}();
								var overlayId = 1 + A2(
									$elm$core$Maybe$withDefault,
									0,
									$elm$core$List$maximum(
										A2(
											$elm$core$List$map,
											function (o) {
												return o.ag;
											},
											model.a.bA)));
								var overlayDragabble = function () {
									var _v5 = model.a_;
									if (!_v5.$) {
										var m = _v5.a;
										var _v6 = m.bJ;
										if (!_v6.$) {
											var o = _v6.a;
											var _v7 = m.aY;
											if (!_v7.$) {
												return '';
											} else {
												return A2(
													$elm$core$Maybe$withDefault,
													'',
													$author$project$BoardOverlay$getBoardOverlayName(o.bJ));
											}
										} else {
											return '';
										}
									} else {
										return '';
									}
								}();
								var monsterId = 1 + A2(
									$elm$core$Maybe$withDefault,
									0,
									$elm$core$List$maximum(
										A2(
											$elm$core$List$map,
											function (m) {
												return m.m.ag;
											},
											model.a.bn)));
								var monsterDraggable = function () {
									var _v1 = model.a_;
									if (!_v1.$) {
										var m = _v1.a;
										var _v2 = m.bJ;
										if (_v2.$ === 1) {
											var p = _v2.a;
											var _v3 = p.bJ;
											if ((_v3.$ === 2) && (!_v3.a.$)) {
												var monster = _v3.a.a;
												var _v4 = m.aY;
												if (!_v4.$) {
													return '';
												} else {
													return A2(
														$elm$core$Maybe$withDefault,
														'',
														$author$project$Monster$monsterTypeToString(monster.m));
												}
											} else {
												return '';
											}
										} else {
											return '';
										}
									} else {
										return '';
									}
								}();
								return _List_fromArray(
									[
										_Utils_Tuple2(
										'map-tile-list',
										A4($elm$html$Html$Lazy$lazy3, $author$project$Creator$getMapTileListHtml, model.a.bT, roomDragabble, model.C)),
										_Utils_Tuple2(
										'board-door-list',
										A6($elm$html$Html$Lazy$lazy5, $author$project$Creator$getOverlayListHtml, overlayId, model.aT, 'Doors', overlayDragabble, model.C === 1)),
										_Utils_Tuple2(
										'board-obstacle-list',
										A6($elm$html$Html$Lazy$lazy5, $author$project$Creator$getOverlayListHtml, overlayId, model.aV, 'Obstacles', overlayDragabble, model.C === 2)),
										_Utils_Tuple2(
										'board-misc-list',
										A6($elm$html$Html$Lazy$lazy5, $author$project$Creator$getOverlayListHtml, overlayId, model.aU, 'Misc.', overlayDragabble, model.C === 3)),
										_Utils_Tuple2(
										'board-monster-list',
										A4($elm$html$Html$Lazy$lazy3, $author$project$Creator$getScenarioMonsterListHtml, monsterId, monsterDraggable, model.C === 4)),
										_Utils_Tuple2(
										'board-boss-list',
										A4($elm$html$Html$Lazy$lazy3, $author$project$Creator$getScenarioBossListHtml, monsterId, monsterDraggable, model.C === 5))
									]);
							}()),
							A2(
							$elm$html$Html$div,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('board-wrapper')
								]),
							_List_fromArray(
								[
									A2(
									$elm$html$Html$div,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('map-bg')
										]),
									_List_Nil),
									function () {
									var _v11 = function () {
										var _v12 = model.a_;
										if (!_v12.$) {
											var m = _v12.a;
											var _v13 = m.bJ;
											if (_v13.$ === 2) {
												var r = _v13.a;
												var ref = A2(
													$elm$core$Maybe$withDefault,
													'',
													$author$project$BoardMapTile$refToString(r.bJ));
												var _v14 = m.b9;
												if (!_v14.$) {
													var _v15 = _v14.a;
													var x1 = _v15.a;
													var y1 = _v15.b;
													return _Utils_Tuple3(ref, x1, y1);
												} else {
													return _Utils_Tuple3('', 0, 0);
												}
											} else {
												return _Utils_Tuple3('', 0, 0);
											}
										} else {
											return _Utils_Tuple3('', 0, 0);
										}
									}();
									var c = _v11.a;
									var x = _v11.b;
									var y = _v11.c;
									return A5($elm$html$Html$Lazy$lazy4, $author$project$Creator$getLazyMapTileHtml, model.a.bT, c, x, y);
								}(),
									A3(
									$elm$html$Html$Keyed$node,
									'div',
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('board')
										]),
									function () {
										var encodedDraggable = function () {
											var _v22 = model.a_;
											if (!_v22.$) {
												var c = _v22.a;
												return A2(
													$elm$json$Json$Encode$encode,
													0,
													$author$project$AppStorage$encodeMoveablePiece(c));
											} else {
												return '';
											}
										}();
										var draggableCoords = function () {
											var _v16 = model.a_;
											if (!_v16.$) {
												var m = _v16.a;
												var _v17 = m.bJ;
												if (!_v17.$) {
													var o = _v17.a;
													var targetCoords = function () {
														var _v19 = m.b9;
														if (!_v19.$) {
															return o.S;
														} else {
															return _List_Nil;
														}
													}();
													var coordList = function () {
														var _v18 = m.aY;
														if (!_v18.$) {
															var initCoords = _v18.a;
															return A3(
																$elm$core$List$foldl,
																$elm$core$Basics$append,
																_List_Nil,
																A2(
																	$elm$core$List$filter,
																	function (c1) {
																		return A2(
																			$elm$core$List$any,
																			function (c) {
																				return _Utils_eq(c, initCoords);
																			},
																			c1);
																	},
																	A2(
																		$elm$core$List$map,
																		function (o1) {
																			return o1.S;
																		},
																		model.a.bA)));
														} else {
															return _List_Nil;
														}
													}();
													return _Utils_ap(coordList, targetCoords);
												} else {
													return _Utils_ap(
														function () {
															var _v20 = m.aY;
															if (!_v20.$) {
																var initCoords = _v20.a;
																return _List_fromArray(
																	[initCoords]);
															} else {
																return _List_Nil;
															}
														}(),
														function () {
															var _v21 = m.b9;
															if (!_v21.$) {
																var targetCoords = _v21.a;
																return _List_fromArray(
																	[targetCoords]);
															} else {
																return _List_Nil;
															}
														}());
												}
											} else {
												return _List_Nil;
											}
										}();
										return A2(
											$elm$core$List$indexedMap,
											A3($author$project$Creator$getBoardRowHtml, model, encodedDraggable, draggableCoords),
											A2(
												$elm$core$List$repeat,
												$author$project$Creator$gridSize,
												A2($elm$core$List$repeat, $author$project$Creator$gridSize, 0)));
									}()),
									A7($elm$html$Html$Lazy$lazy6, $author$project$Creator$getContextMenu, model.J, model.au, model.at, model.c, model.a.bA, model.a.bn)
								])),
							A3($elm$html$Html$Lazy$lazy2, $author$project$Creator$getErrorStatusHtml, model.af, model.X)
						]))),
				_Utils_Tuple2(
				'foot',
				A2($elm$html$Html$Lazy$lazy, $author$project$BoardHtml$getFooterHtml, $author$project$Version$get))
			]));
};
var $author$project$Creator$main = $elm$browser$Browser$element(
	{cS: $author$project$Creator$init, dB: $author$project$Creator$subscriptions, dN: $author$project$Creator$update, dQ: $author$project$Creator$view});
_Platform_export({'Creator':{'init':$author$project$Creator$main(
	$elm$json$Json$Decode$oneOf(
		_List_fromArray(
			[
				$elm$json$Json$Decode$null($elm$core$Maybe$Nothing),
				A2($elm$json$Json$Decode$map, $elm$core$Maybe$Just, $elm$json$Json$Decode$value)
			])))(0)}});}(this));