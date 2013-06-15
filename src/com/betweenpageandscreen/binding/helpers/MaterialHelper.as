package com.betweenpageandscreen.binding.helpers
{
  import com.bradwearsglasses.utils.helpers.GraphicsHelper;
  import com.bradwearsglasses.utils.helpers.LayoutHelper;
  
  import flash.display.BitmapData;
  import flash.display.Sprite;
  
  import org.papervision3d.materials.BitmapMaterial;
  import org.papervision3d.materials.MovieMaterial;

  public class MaterialHelper {

    public static function bitmap_mat(texture:Sprite, padding:Number = 25, scale:Number=1,doublesided:Boolean=true, precise:Boolean=true, smooth:Boolean=true):BitmapMaterial {
      texture.scaleX = texture.scaleY = scale;
      var template:Sprite = new Sprite;
      GraphicsHelper.strut(template, GraphicsHelper.rect(texture.width+padding, texture.height+padding));
      LayoutHelper.in_center(template, template, texture, null,true);

      var b:BitmapData = new BitmapData(template.width,template.height,true,0x00FFFFFF);
      b.draw(template,null,null,null,null,true);

      var bmp:BitmapMaterial = new BitmapMaterial(b,precise);
      bmp.doubleSided = doublesided;
      bmp.baked = true;
      bmp.smooth = smooth;
      bmp.interactive = false;

      return bmp;
    }
    
    public static function movie_mat(texture:Sprite, padding:Number = 25, doublesided:Boolean=true):BitmapMaterial {
      texture.scaleX = texture.scaleY = 3;
      var template:Sprite = new Sprite;
      GraphicsHelper.strut(template, GraphicsHelper.rect(texture.width+padding, texture.height+padding));

      LayoutHelper.in_center(template, template, texture, null,true);

      var mat:MovieMaterial = new MovieMaterial(template,true);
      mat.doubleSided = doublesided;
      mat.baked = true;
      mat.smooth = true;

      return mat;
    }
    
  }
}
