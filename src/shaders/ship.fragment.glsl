uniform vec3 sunDirection;
uniform float u_time;

in mat4 shipModelMatrix;
in vec3 cameraToVertex;

mat4 translationMatrix(float x, float y, float z) {
  return mat4(
    1.0, 0.0, 0.0, 0.0,
    0.0, 1.0, 0.0, 0.0,
    0.0, 0.0, 1.0, 0.0,
    x, y, z, 1.0
  );
}

mat4 rotationMatrix(float angleX, float angleY, float angleZ) {
  float cosX = cos(angleX);
  float sinX = sin(angleX);
  float cosY = cos(angleY);
  float sinY = sin(angleY);
  float cosZ = cos(angleZ);
  float sinZ = sin(angleZ);

  mat4 rotationX = mat4(
    1.0, 0.0, 0.0, 0.0,
    0.0, cosX, -sinX, 0.0,
    0.0, sinX, cosX, 0.0,
    0.0, 0.0, 0.0, 1.0
  );

  mat4 rotationY = mat4(
    cosY, 0.0, sinY, 0.0,
    0.0, 1.0, 0.0, 0.0,
    -sinY, 0.0, cosY, 0.0,
    0.0, 0.0, 0.0, 1.0
  );

  mat4 rotationZ = mat4(
    cosZ, -sinZ, 0.0, 0.0,
    sinZ, cosZ, 0.0, 0.0,
    0.0, 0.0, 1.0, 0.0,
    0.0, 0.0, 0.0, 1.0
  );

  return rotationX * rotationY * rotationZ;
}

vec3 applyModelMatrix(vec3 position, mat4 matrix) {
  return (matrix * vec4(position, 1.0)).xyz;
}

mat2 rot2D(float angle) {
  float s = sin(angle);
  float c = cos(angle);
  return mat2(c, -s, s, c);
}

float opUnion(float d1, float d2) {
  return min(d1, d2);
}

float opSubtraction(float d1, float d2) {
  return max(-d1, d2);
}

float opIntersection(float d1, float d2) {
  return max(d1, d2);
}

float sdSphere(vec3 point, float r) {
  return length(point) - r;
}

float sdBox(vec3 point, vec3 b) {
  vec3 q = abs(point) - b;
  return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float sdRoundBox(vec3 point, vec3 b, float r) {
  vec3 q = abs(point) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}

float sdCappedCylinder(vec3 p, float h, float r) {
  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(r,h);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float sdLivingSectionQuad(vec3 p) {
  float sphereOuter = sdSphere(p, 1.5);
  float sphereInner = sdSphere(p, 1.45);

  float roundBox = sdRoundBox(p, vec3(.3, 2., .75), .1);
  float box = sdBox(p - vec3(0., 1., 0.), vec3(1., 1., 1.));

  float temp = opIntersection(roundBox, sphereOuter);
  float tempTwo = opSubtraction(sphereInner, temp);

  return opSubtraction(box, tempTwo);
}

float sdLivingSectionHalf(vec3 p) {
  float section_0 = sdLivingSectionQuad(p - vec3(0., 0.5, 0.));
  p.xy *= rot2D(PI);
  float section_1 = sdLivingSectionQuad(p - vec3(0., 0.5, 0.));

  return opUnion(section_0, section_1);
}

float sdLivingSection(vec3 p) {
  float section_0 = sdLivingSectionHalf(p);
  p.xy *= rot2D(PI / 2.);
  float section_1 = sdLivingSectionHalf(p);
  return opUnion(section_0, section_1);
}

float sdCenterSection(vec3 p) {
  p.yz *= rot2D(PI / 2.);
  float size = .9;

  float cylinderOuter = sdCappedCylinder(p, size, .25);
  float cylinderInner = sdCappedCylinder(p, size * 1.1, .2);

  float temp = opSubtraction(cylinderInner, cylinderOuter);
  return temp;
}

float map(vec3 p) {
  float time = u_time * 0.001;
  // p.xy *= rot2D(time);

  p = applyModelMatrix(p, rotationMatrix(0., 0., time) * inverse(shipModelMatrix));
  return opUnion(sdLivingSection(p), sdCenterSection(p));
}

vec3 estimateNormal(vec3 p) {
  return normalize(vec3(
    map(vec3(p.x + EPSILON, p.y, p.z)) - map(vec3(p.x - EPSILON, p.y, p.z)),
    map(vec3(p.x, p.y + EPSILON, p.z)) - map(vec3(p.x, p.y - EPSILON, p.z)),
    map(vec3(p.x, p.y, p.z  + EPSILON)) - map(vec3(p.x, p.y, p.z - EPSILON))
  ));
}

void main() {
  vec3 rayOrigin = cameraPosition;
  vec3 rayDirection = normalize(cameraToVertex);
  vec4 color = vec4(0);

  float t = 0.0;

  for(int i = 0; i < 64; i++) {
    vec3 point = rayOrigin + rayDirection * t;

    float d = map(point);

    t += d;

    if (d > 100.) {
      // color = vec4(vec3(1., .5, 0.), 1.);
      color = vec4(0.);

      break;
    };

    if (d < .001) {
      vec3 normal = estimateNormal(point);
      float light = dot(sunDirection, normal);
      color = vec4(vec3(light), 1.);
      // color = vec4(normal, 1.);
      break;
    };
  }

  gl_FragColor = color;
}






























