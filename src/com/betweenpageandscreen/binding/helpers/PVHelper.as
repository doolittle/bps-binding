package com.betweenpageandscreen.binding.helpers {
import org.papervision3d.core.geom.Lines3D;
import org.papervision3d.core.geom.renderables.Line3D;
import org.papervision3d.core.geom.renderables.Vertex3D;
import org.papervision3d.materials.special.LineMaterial;

public class PVHelper {

  public static function draw_axes():Lines3D {
    // Borrowed from http://blog.tartiflop.com/2008/07/first-steps-in-papervision3d-part-1/
    // Is there a default width for this?
    // Create a default line material and a Lines3D object (container for Line3D objects)
    var defaultMaterial:LineMaterial = new LineMaterial(0xFFFFFF);
    var axes:Lines3D = new Lines3D(defaultMaterial);

    // Create a different colour line material for each axis
    var xAxisMaterial:LineMaterial = new LineMaterial(0xFF0000);
    var yAxisMaterial:LineMaterial = new LineMaterial(0x00FF00);
    var zAxisMaterial:LineMaterial = new LineMaterial(0x0000FF);

    // Create a origin vertex
    var origin:Vertex3D = new Vertex3D(0, 0, -5);

    // Create a new line (length 100) for each axis using the different materials and a width of 2.
    var xAxis:Line3D = new Line3D(axes, xAxisMaterial, 4, origin, new Vertex3D(60, 0, 0));
    var yAxis:Line3D = new Line3D(axes, yAxisMaterial, 4, origin, new Vertex3D(0, 60, 0));
    var zAxis:Line3D = new Line3D(axes, zAxisMaterial, 4, origin, new Vertex3D(0, 0, -60));

    // Add lines to the Lines3D container
    axes.addLine(xAxis);
    axes.addLine(yAxis);
    axes.addLine(zAxis);
    return axes;
  }

}
}
