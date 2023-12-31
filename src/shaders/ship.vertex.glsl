out mat4 shipModelMatrix;
out vec3 cameraToVertex;

void main() {
  shipModelMatrix = modelMatrix;
  cameraToVertex = (modelMatrix * vec4(position, 1.0)).xyz - cameraPosition;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
