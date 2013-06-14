package com.betweenpageandscreen.binding.models
{
  import com.betweenpageandscreen.binding.config.BookConfig;
  
  import flash.utils.ByteArray;
  
  import org.libspark.flartoolkit.core.FLARParam;

  public class CameraParams
  {
    private var _params:FLARParam
    public function get params():FLARParam {
      return _params; 
    }
    
    public function update(data:ByteArray):void {
      _params = new FLARParam();
      _params.loadARParamFile(data);
      _params.changeScreenSize(BookConfig.SAMPLE_WIDTH, BookConfig.SAMPLE_HEIGHT);
    }
  }
}