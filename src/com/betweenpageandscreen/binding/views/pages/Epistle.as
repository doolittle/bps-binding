package com.betweenpageandscreen.binding.views.pages
{
import com.betweenpageandscreen.binding.events.BookEvent;
import com.betweenpageandscreen.binding.helpers.LetterHelper;
import com.betweenpageandscreen.binding.views.modules.BookModule;
import com.betweenpageandscreen.binding.views.modules.Letter;
import com.bradwearsglasses.utils.debug.DebugTimer;
import com.bradwearsglasses.utils.helpers.GeneralHelper;
import com.bradwearsglasses.utils.helpers.NumberHelper;

import flash.display.Sprite;
import flash.events.Event;

import org.libspark.flartoolkit.support.pv3d.FLARMarkerNode;
import org.papervision3d.objects.DisplayObject3D;

public class Epistle extends BookModule
{
  private var container:Sprite;
  private var marker:FLARMarkerNode;

  private var content:String;
  private var lines:Array;
  private var phrase:Array = [];

  private var max_line_width:int = 0;
  private var text:DisplayObject3D;
  private var justify:Boolean = false;

  private var to_destroy:int = 0;
  private var destroyed:int = 0;

  private var text_id:int;

  public function Epistle(epistle_text:String, _justify:Boolean=true){
    text_id = GeneralHelper.generate_id();
    content = epistle_text;
    justify = _justify;
    text = new DisplayObject3D;
    lines = content.split("\n");
  }

  override public function init(_container:Sprite, _marker:*):void {
    if (hasEventListener(BookEvent.MODULE_DESTROY)) {
      removeEventListener(BookEvent.MODULE_DESTROY,destroy);
    }
    container = _container;
    marker = _marker as FLARMarkerNode;

    trace(text_id + ":\tIniting epistle:"
        + phrase.length +
        " phrase length and "
        + lines.length
        + " lines");

    iterate_phrase(phrase,
        function(l:Letter, ...rest):void {
          destroy_letter(null, l, true);
        });

    // Note: module is not automatically intro'd.
    // It could be inited w/o displayed.
  }

  override public function intro():void {
    trace("Introing epistle:" + text_id + "| to destroy:" + to_destroy);
    // Text is flopped so xyz don't line up exactly:
    text.z = -160; // Up down, lower numbers are vertically higher.
    text.x = -45; // left right
    text.y = 0; //Depth
    text.rotationX = 180;
    text.rotationY = 0;
    text.rotationZ = 90;
    text.scale = .66;
    var prepopulated:Boolean = (phrase.length > 0);
    var timer:DebugTimer = new DebugTimer("Creating lines (" + prepopulated + ")");

    lines.forEach(function(...rest):void {
      max_line_width = LetterHelper.line(rest[0], rest[1], rest[2], justify, phrase, text, max_line_width,prepopulated);
    });

    timer.mark("Lines created");
    marker.addChild(text)
  }

  override public function tick():void {}

  override public function remove():void {
    trace("Removing epistle.");
    if (!hasEventListener(BookEvent.MODULE_DESTROY)) {
      addEventListener(BookEvent.MODULE_DESTROY,destroy);
    }
    explode();
  }

  private function explode():void {
    to_destroy = 0;
    destroyed = 0;
    trace("Exploding");
    iterate_phrase(phrase, queue_destroy_letter);
  }

  private function queue_destroy_letter(l:Letter, ...rest):void {
    //trace("Queueing destroy:" + to_destroy);
    if (NumberHelper.sample(5)) return destroy_letter(null, l, true); //drop 20% of letters to make remainder faster.
    to_destroy++;
    LetterHelper.exit(l, container, destroy_letter, 'explode');  //ArrayHelper.random(['explode', 'drop', 'up']) as String
  }

  private function destroy_letter(event:Event=null, _l:Letter=null, auto:Boolean=false):void {
    var l:Letter = (_l) ? _l :  event.target as Letter;
    if (!auto) {
      destroyed++;
      to_destroy--;
    }
    //trace("Letter destroyed:" + destroyed + "/" + to_destroy);
    l.removeEventListener(Event.COMPLETE, destroy_letter);
    text.removeChild(l.character);
    if (to_destroy===0 && !auto) {
      request_destroy();
    }
  }

  private function destroy(event:*=null):void {
    trace("Destroying Epistle");
    if (hasEventListener(BookEvent.MODULE_DESTROY)) {
      removeEventListener(BookEvent.MODULE_DESTROY,destroy);
    }
    marker.removeChild(text);

  }

}
}
