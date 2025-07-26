package state;

import echo.Material;
import hxd.Key;
import echo.Body;
import echo.World;
import util.Random;

class ArcTileState extends BaseState {
  var body_count:Int = 1;

  var cursor:Body;
  var cursor_speed:Float = 10;

  var kicker:Body;

  override public function enter(world:World) {
    Main.instance.state_text.text = "Sample: Arc Tiles";

    // Create a material for all the shapes to share
    var material:Material = {elasticity: 0.2};

    // Add a bunch of random Physics Bodies to the World
    for (i in 0...body_count) {
      var scale = Random.range(0.3, 1);
      var b = new Body({
        x: world.width / 2 + 2,
        y: world.height / 2 - 120,
        rotation: 0,
        material: material,
        shape: {
          type: CIRCLE,
          radius: Random.range(10, 10),
        }
      });
      world.add(b);
    }

    // Add a Physics body at the bottom of the screen for the other Physics Bodies to stack on top of
    // This body has a mass of 0, so it acts as an immovable object
    var mainRamp = new Body({
      mass: STATIC,
      x: world.width / 2 + world.width / 8,
      y: world.height / 2,
      material: material,
      //   rotation: 5,
      shape: {
        type: ARC_TILE,
        width: world.width / 4,
        height: world.width / 4,
        inverted: true
      }
    });

    var kicker = new Body({
      mass: STATIC,
      x: mainRamp.shape.right + 40,
      y: world.height / 2 + world.width / 8 - 20,
      material: material,
      // rotation: 90,
      shape: {
        type: ARC_TILE,
        curvature: -0,
        rotation: -90,
        width: 40,
        height: 80,
      }
    });

    var kicker2 = new Body({
      mass: STATIC,
      x: mainRamp.shape.left - 60,
      y: world.height / 2 + world.width / 8,
      material: material,
      // rotation: 90,
      shape: {
        type: ARC_TILE,
        rotation: -45,
        width: 40,
        height: 40,
      }
    });

    var kicker3 = new Body({
      mass: STATIC,
      x: mainRamp.shape.left - 130,
      y: world.height / 2 + world.width / 8,
      material: material,
      // rotation: 90,
      shape: {
        type: ARC_TILE,
        rotation: 180,
        width: 40,
        height: 40,
      }
    });

    var offset = 0;
    for (i in 0...20) {
      offset += 30;
      var rotTest = new Body({
        mass: STATIC,
        x: offset,
        y: 20,
        material: material,
        // rotation: 90,
        shape: {
          type: ARC_TILE,
          rotation: -offset / 6,
          width: 40,
          height: 40,
        }
      });
      world.add(rotTest);
    }

    cursor = new Body({
      x: Main.instance.scene.mouseX,
      y: Main.instance.scene.mouseY,
      shape: {
        type: CIRCLE,
        radius: 16
      }
    });

    world.add(cursor);
    world.add(mainRamp);
    world.add(kicker);
    world.add(kicker2);
    world.add(kicker3);

    // Create a listener for collisions between the Physics Bodies
    world.listen();
  }

  override function step(world:World, dt:Float) {
    // Move the Cursor Body
    cursor.velocity.set(Main.instance.scene.mouseX - cursor.x, Main.instance.scene.mouseY - cursor.y);
    cursor.velocity *= cursor_speed;

    // Reset any off-screen Bodies
    world.for_each((member) -> {
      if (offscreen(member, world)) {
        member.velocity.set(0, 0);
        member.set_position(world.width / 2 + (Random.range(1, 10) - 5), world.height / 2 - 120);
      }
    });
  }
}
