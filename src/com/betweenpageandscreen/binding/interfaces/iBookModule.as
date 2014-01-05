package com.betweenpageandscreen.binding.interfaces
{
  import flash.display.Sprite;
  
  public interface iBookModule
  {
    function get id():int;
    function set id(n:int):void;
    function intro():void;
    function remove():void;
    function init(_container:Sprite, _marker:*):void;
    function tick():void;
       
  }
}