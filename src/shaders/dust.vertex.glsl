out vec3 cameraToVertex;

void main() {
  cameraToVertex = (modelMatrix * vec4(position, 1.0)).xyz - cameraPosition;
  gl_PointSize = 50. / length(cameraToVertex) * .5;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}

