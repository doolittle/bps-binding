package com.betweenpageandscreen.binding.interfaces
{
  import flash.display.Sprite;

import org.papervision3d.core.math.Number3D;

public interface iBookModule
  {
    function get preview_position():Number3D;
    function set preview_position(n:Number3D):void;
    function get preview_rotation():Number3D;
    function set preview_rotation(n:Number3D):void;
    function get preview_scale():Number;
    function set preview_scale(n:Number):void;

    function get id():int;
    function set id(n:int):void;
    function intro():void;
    function remove():void;
    function init(_container:Sprite, _marker:*):void;
    function tick():void;
       
  }
}