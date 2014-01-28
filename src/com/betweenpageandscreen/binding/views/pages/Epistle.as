package com.betweenpageandscreen.binding.views.pages
{
import com.betweenpageandscreen.binding.events.BookEvent;
import com.betweenpageandscreen.binding.helpers.LetterHelper;
import com.betweenpageandscreen.binding.views.modules.BookModule;
import com.betweenpageandscreen.binding.views.modules.Letter;
import com.bradwearsglasses.utils.helpers.GeneralHelper;
import com.bradwearsglasses.utils.helpers.NumberHelper;

import flash.display.Sprite;
import flash.events.Event;

import org.libspark.flartoolkit.support.pv3d.FLARMarkerNode;
import org.papervision3d.objects.DisplayObject3D;

public class Epistle extends BookModule
{
  private var container:Sprite;
  protected var marker:FLARMarkerNode;

  private var content:String;
  private var lines:Array;
  private var phrase:Array = [];

  private var max_line_width:int = 0;
  private var text:DisplayObject3D;

  private var justify:Boolean = false;
  private var auto_position:Boolean = false; //Whether to center the epistle based on its size.

  private var to_destroy:int = 0;
  private var destroyed:int = 0;

  private var text_id:int;

  public function Epistle(epistle_text:String, _justify:Boolean=true, _auto_position:Boolean = false){
    text_id = GeneralHelper.generate_id();
    content = epistle_text;
    justify = _justify;
    auto_position = _auto_position;
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
    // Text is rotated so y and z are reversed (z is up/down, y, depth)
    place_letters();
    marker.addChild(text)
  }

  // This is used for the epistler, where writers can
  // see their epistle update as they type.
  public function update_text(epistle_text:String):void {
    content = epistle_text;
    explode();
    lines = content.split("\n");
    phrase = [];
    place_letters();
  }

  public function place_letters():void {

    text.y = -40; //Depth
    text.rotationX = 180;
    text.rotationY = 0;
    text.rotationZ = 90;
    text.scale = 0.66;

    var prepopulated:Boolean = (phrase.length > 0);
    //var timer:DebugTimer = new DebugTimer("Creating lines (" + prepopulated + ")");

    max_line_width = 0;

    lines.forEach(function(...rest):void {
      max_line_width = LetterHelper.line(
          rest[0], rest[1], rest[2],
          justify, phrase, text, max_line_width,
          prepopulated,'from_marker', !auto_position);
    });

    if (auto_position) {
      text.z = -vertical_position_text(lines.length,9, 20, text.scale);
      text.x = -36; //We won't mess with L/R placement for now.
    } else {
      text.z = -180; // Up down, lower numbers are vertically higher.
      text.x = -36; // left right
    }

    //timer.mark("Lines created");

  }

  private function vertical_position_text(num_lines:int, optimal_num_lines:int, floor:int, scale:Number=1):int {

    var offset:int = ((num_lines*LetterHelper.LINE_HEIGHT)*scale) + floor;

    if (num_lines < optimal_num_lines) {
      // This text is short, so we should add some padding.
      // return half the difference + floor
      offset+=(((optimal_num_lines-num_lines)*LetterHelper.LINE_HEIGHT)*scale)/2;
    }

    return offset;
  }

  override public function tick():void {}

  override public function remove():void {
    if (!hasEventListener(BookEvent.MODULE_DESTROY)) {
      addEventListener(BookEvent.MODULE_DESTROY,destroy);
    }
    explode();
  }

  private function explode():void {
    to_destroy = 0;
    destroyed = 0;
    iterate_phrase(phrase, queue_destroy_letter);
  }

  private function queue_destroy_letter(l:Letter, ...rest):void {
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
