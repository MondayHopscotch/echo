package state;

import echo.Material;
import hxd.Key;
import echo.Body;
import echo.World;
import util.Random;

class ArcTileState extends BaseState {
  var body_count:Int = 10;

  override public function enter(world:World) {
    Main.instance.state_text.text = "Sample: Arc Tiles";

    // Create a material for all the shapes to share
    var material:Material = {elasticity: 0.9};

    // Add a bunch of random Physics Bodies to the World
    for (i in 0...body_count) {
      var scale = Random.range(0.3, 1);
      var b = new Body({
        x: world.width / 2 + Random.range(0, 60),
        y: world.height / 2 + Random.range(0, 60),
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
    world.add(new Body({
      mass: STATIC,
      x: world.width / 2,
      y: world.height / 2,
      material: material,
      //   rotation: 5,
      shape: {
        type: ARC_TILE,
        width: world.width / 2,
        height: world.width / 2,
        inverted: true
      }
    }));

    // Create a listener for collisions between the Physics Bodies
    world.listen();
  }

  override function step(world:World, dt:Float) {
    // Reset any off-screen Bodies
    world.for_each((member) -> {
      if (offscreen(member, world)) {
        member.velocity.set(0, 0);
        member.set_position(world.width / 2 + Random.range(0, 60), world.height / 2 + Random.range(0, 60));
      }
    });
  }
}
