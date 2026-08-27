import { Schema, type } from "@colyseus/schema";

export class MatchDeployableSchema extends Schema {
  @type("string") type = "";
  @type("int8") owner = -1;
  @type("float32") x = 0;
  @type("float32") y = 0;
  @type("float32") dx = 0;
  @type("float32") dy = 0;
  @type("float32") tdx = 0;
  @type("float32") tdy = 0;
  @type("float32") halfLength = 0;
  @type("float32") lifetime = 0;
  @type("float32") maxLifetime = 0;
  @type("float32") armTime = 0;
  @type("float32") armDuration = 0;
  @type("boolean") triggered = false;
  @type("float32") triggerRadius = 0;
  @type("float32") blastRadius = 0;
  @type("float32") fuseTime = 0;
  @type("float32") fuseDuration = 0;
}
