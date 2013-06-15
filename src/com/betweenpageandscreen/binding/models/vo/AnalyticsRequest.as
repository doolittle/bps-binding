package com.betweenpageandscreen.binding.models.vo
{
  public class AnalyticsRequest
  {
    public var path:String;
    public var event:Boolean = false;
    public var category:String;
    public var value:Number;
    
    public static var EVENT:String = 'event';
    public static var EXCEPTION:String = 'exception';
    
    public function AnalyticsRequest(p:String, is_event:Boolean=false, _category:String=null,_value:Number=-1){
      path = p;
      event = is_event;
      category = _category;
      value = _value;
    }
    
  }
}