package com.betweenpageandscreen.binding.interfaces
{
  import flash.display.Sprite;
  
  public interface iBookModule
  {
    function get id():Number;
    function set id(n:Number):void;
    function intro():void;
    function remove():void;
    function init(c:Sprite, m:*):void;
    function tick():void;
       
  }
}