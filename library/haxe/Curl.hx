package haxe;

import haxe.Http;
import haxe.io.BytesOutput;
import sys.net.Host;
using StringTools;

private typedef AbstractSocket =
{
	var input(default,null) : haxe.io.Input;
	var output(default,null) : haxe.io.Output;
	function connect( host : Host, port : Int ) : Void;
	function setTimeout( t : Float ) : Void;
	function write( str : String ) : Void;
	function close() : Void;
	function shutdown( read : Bool, write : Bool ) : Void;
}

class Curl
{
	public static function request(method:String, url:String, ?data:Dynamic, ?headers:Array<String>) : String
	{
		var http = new Http(url);
		
		if (data != null) for (p in Reflect.fields(data))
		{
			http.addParameter(p, Std.string(Reflect.field(data, p)));
		}
		
		if (headers != null) for (h in headers)
		{
			var nameValue = h.split(":");
			http.addHeader(nameValue[0], nameValue.slice(1).join(":"));
		}
		
		http.onError = function(msg)
		{
			trace("ERROR get '" + url + "': " + msg);
		};
		
		http.noShutdown = true;
		http.cnxTimeout = 10;
		
		return requestInner(false, http, data, headers);
	}
	
	public static function get(url:String, ?data:Dynamic, ?headers:Array<String>) : String
	{
		return request("GET", url, data, headers);
	}
	
	public static function post(url:String, ?data:Dynamic, ?headers:Array<String>) : String
	{
		return request("POST", url, data, headers);
	}
	
	static function requestInner(post:Bool, http:Http, ?data:Dynamic, ?headers:Array<String>) : String
	{
		try
		{
			var buf = new BytesOutput();
			http.customRequest(post, buf, createSocket(http.url.startsWith("https://")));
			return buf.getBytes().toString();
		}
		catch (e:Dynamic)
		{
			trace("Error " + (post ? "post" : "get") + " request url '" + http.url + "':");
			trace(e);
			if (data != null) trace(data);
			if (headers != null) trace("\tHEADERS:\n\t\t" + headers.join("\n\t\t"));
			return null;
		}
	}
	
	static function createSocket(secure:Bool) : AbstractSocket
	{
		if (secure)
		{
			var sock = null;
			
			#if php
			sock = new php.net.SslSocket();
			#elseif java
			sock = new java.net.SslSocket();
			#elseif hxssl
			#if neko
			sock = new neko.tls.Socket();
			#else
			sock = new sys.ssl.Socket();
			#end
			#else
			throw "Https is only supported with -lib hxssl";
			#end
			
			sock.validateCert = false;
			
			return sock;
		}
		
		return new sys.net.Socket();
	}
}