package com.betweenpageandscreen.binding.views.modules
{
  import com.betweenpageandscreen.binding.events.BookEvent;
  import com.betweenpageandscreen.binding.interfaces.iBookModule;
  
  import flash.display.Sprite;
  import flash.events.EventDispatcher;
  
  import org.libspark.betweenas3.core.tweens.ObjectTween;

  public class BookModule extends EventDispatcher implements iBookModule 
  {
    private var _id:Number;
    protected var exit_tween:ObjectTween;
   
    protected function setup():void { }
    
    public function set id(n:Number):void { _id = n; }
    public function get id():Number { return _id; }            
    public function init(c:Sprite, m:*):void { }
    public function tick():void {}
    public function intro():void { }
    public function remove():void {}
    
    protected function iterate_phrase(phrase:Object, method:Function):void {
      phrase.forEach(function(a:Array, ...rest):void { 
        if (!a) return;
        a.forEach(function(l:Letter, ...rest):void {
          method(l);
        })
      })
    }
        
    protected function request_destroy():void { //Sends the request to destroy the module. Listener is reset on init, so we don't kill an existing module when the outro is finished. 
      dispatchEvent(new BookEvent(BookEvent.MODULE_DESTROY)); 
    }

  }
}
