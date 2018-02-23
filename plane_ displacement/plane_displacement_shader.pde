import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.FloatBuffer;
import java.nio.IntBuffer;

import com.jogamp.opengl.GL;
import com.jogamp.opengl.GLBase;
import com.jogamp.opengl.GLProfile;
import com.jogamp.opengl.GL2ES2;

import com.jogamp.opengl.util.texture.Texture;
import com.jogamp.opengl.util.texture.TextureData;
import com.jogamp.opengl.util.texture.TextureIO;

PShader shader;

int SIZE = 400;
int RESOLUTION = 1;
int planeSize = SIZE/RESOLUTION;
int numVerts = planeSize * planeSize;
int numIndices = (planeSize-1) * (planeSize-1) * 2 * 3;

float[] positions;
float[] colours;
float[] texCoords;
int[] indices;
float[] texturePixels;
TextureData textureMapData;
Texture textureMap;


FloatBuffer posBuffer;
FloatBuffer colourBuffer;
FloatBuffer texCoordsBuffer;
IntBuffer indexBuffer;

int posVboId;
int colourVboId;
int texCoordsVboId;
int indexVboId;
int textureVboId;
int timeVboId;

int posLoc; 
int colourLoc;
int texCoordsLoc;
int textureLoc;
int timeLoc;

PJOGL pgl;
GL2ES2 gl;

void setup() {
  size(600, 600, P3D);

  positions = new float[numVerts*4];
  colours = new float[numVerts*4];
  texCoords = new float[numVerts*2];
  indices = new int[numIndices];

  shader = loadShader("frag.glsl", "vert.glsl");

  posBuffer = allocateDirectFloatBuffer(numVerts*4);
  colourBuffer = allocateDirectFloatBuffer(numVerts*4); 
  texCoordsBuffer = allocateDirectFloatBuffer(numVerts*2);
  indexBuffer = allocateDirectIntBuffer(numIndices); 

  pgl = (PJOGL) beginPGL();  
  gl = pgl.gl.getGL2ES2();

  File file = new File(dataPath("../displacement_map32.jpg"));
  //File file = new File(dataPath("../flower.jpg"));
  try {
    textureMapData = TextureIO.newTextureData(GLProfile.get(GLProfile.GL2ES2), file, false, "jpg");
    textureMap = TextureIO.newTexture(gl, textureMapData);
    println(textureMapData);
    println(textureMap);
  } 
  catch (IOException e) {
    exit();
  }

  textureMap.setTexParameteri(gl, GL.GL_TEXTURE_WRAP_S, GL.GL_MIRRORED_REPEAT);
  textureMap.setTexParameteri(gl, GL.GL_TEXTURE_WRAP_T, GL.GL_MIRRORED_REPEAT);
  textureMap.setTexParameteri(gl, GL.GL_TEXTURE_MIN_FILTER, GL.GL_NEAREST);
  textureMap.setTexParameteri(gl, GL.GL_TEXTURE_MAG_FILTER, GL.GL_NEAREST);

  // Get GL ids for all the buffers
  IntBuffer intBuffer = IntBuffer.allocate(5);  
  gl.glGenBuffers(5, intBuffer);
  posVboId = intBuffer.get(0);
  colourVboId = intBuffer.get(1);
  texCoordsVboId = intBuffer.get(2);
  indexVboId = intBuffer.get(3);  
  timeVboId = intBuffer.get(4);

  IntBuffer intBuffer1 = IntBuffer.allocate(1);  
  gl.glGenTextures(1, intBuffer1);
  textureVboId = intBuffer1.get(0);

  // Get the location of the attribute variables.
  shader.bind();
  posLoc = gl.glGetAttribLocation(shader.glProgram, "position");
  colourLoc = gl.glGetAttribLocation(shader.glProgram, "color");
  texCoordsLoc = gl.glGetAttribLocation(shader.glProgram, "texCoord");
  //textureLoc = gl.glGetUniformLocation(shader.glProgram, "texture");
  timeLoc = gl.glGetUniformLocation(shader.glProgram, "u_time");
  shader.unbind();  

  createGeometry();

  endPGL();
}

void draw() {
  background(41);

  text(round(frameRate), 0, 10);
  
  translate(width/2, height/2);
  rotateX(map(mouseY, height, 0, -PI, PI));
  rotateY(map(mouseX, 0, width, -PI, PI));  

  pgl = (PJOGL) beginPGL();  
  gl = pgl.gl.getGL2ES2();

  shader.bind();
  gl.glEnableVertexAttribArray(posLoc);
  gl.glEnableVertexAttribArray(colourLoc);  
  gl.glEnableVertexAttribArray(texCoordsLoc);  

  // Copy vertex data to VBOs
  gl.glBindBuffer(GL.GL_ARRAY_BUFFER, posVboId);
  gl.glBufferData(GL.GL_ARRAY_BUFFER, Float.BYTES * positions.length, posBuffer, GL.GL_DYNAMIC_DRAW);
  gl.glVertexAttribPointer(posLoc, 4, GL.GL_FLOAT, false, 4 * Float.BYTES, 0);

  gl.glBindBuffer(GL.GL_ARRAY_BUFFER, colourVboId);  
  gl.glBufferData(GL.GL_ARRAY_BUFFER, Float.BYTES * colours.length, colourBuffer, GL.GL_DYNAMIC_DRAW);
  gl.glVertexAttribPointer(colourLoc, 4, GL.GL_FLOAT, false, 4 * Float.BYTES, 0);

  gl.glBindBuffer(GL.GL_ARRAY_BUFFER, texCoordsVboId);  
  gl.glBufferData(GL.GL_ARRAY_BUFFER, Float.BYTES * texCoords.length, texCoordsBuffer, GL.GL_DYNAMIC_DRAW);
  gl.glVertexAttribPointer(texCoordsLoc, 2, GL.GL_FLOAT, false, 2 * Float.BYTES, 0);


  // Texture
  //gl.glActiveTexture(GL.GL_TEXTURE0);
  textureMap.enable(gl);
  textureMap.bind(gl);
  //gl.glUniform1i(textureLoc, 0);
  textureMap.disable(gl);
  
  //Time
  gl.glUniform1f(timeLoc, float(frameCount)/100);

  gl.glBindBuffer(GL.GL_ARRAY_BUFFER, 0);

  // Draw the triangle elements
  gl.glBindBuffer(PGL.ELEMENT_ARRAY_BUFFER, indexVboId);
  pgl.bufferData(PGL.ELEMENT_ARRAY_BUFFER, Integer.BYTES * indices.length, indexBuffer, GL.GL_DYNAMIC_DRAW);
  gl.glDrawElements(PGL.TRIANGLES, indices.length, GL.GL_UNSIGNED_INT, 0);
  gl.glBindBuffer(PGL.ELEMENT_ARRAY_BUFFER, 0);    

  gl.glDisableVertexAttribArray(posLoc);
  gl.glDisableVertexAttribArray(colourLoc); 
  gl.glDisableVertexAttribArray(texCoordsLoc); 
  shader.unbind();

  endPGL();

  //labelVertices();

  System.gc();
}

void createGeometry() {

  PVector pos = new PVector(-SIZE/2, 0, -SIZE/2);
  for (int y = 0; y < planeSize; y++) {
    for (int x = 0; x < planeSize; x++) {

      int index = (x + y * planeSize)*4;

      positions[index]   = pos.x + x * RESOLUTION;
      positions[index+1] = pos.y;
      positions[index+2] = pos.z + y * RESOLUTION;
      positions[index+3] = 1;     

      colours[index]   = map(x, 0, planeSize, 0.0, 1.0);
      colours[index+1] = map(y, 0, planeSize, 0.0, 1.0);
      colours[index+2] = map(x+y, 0, planeSize*2, 0.0, 1.0);
      colours[index+3] = 1.0;
    }
  }

  int row = 1;
  int quadCount = 0;
  // Make quads
  for (int i = 0; i < numIndices; i+=6) {
    // Triangle 1
    indices[i] = quadCount;
    indices[i+1] = quadCount+1;
    indices[i+2] = quadCount+planeSize;

    // Triangle 2
    indices[i+3] = quadCount+planeSize;
    indices[i+4] = quadCount+planeSize+1;
    indices[i+5] = quadCount+1;

    quadCount++;
    if (quadCount == row * planeSize - 1) {
      quadCount++;
      row++;
    }
  }

  for (int y = 0; y < planeSize; y++) {
    for (int x = 0; x < planeSize; x++) {

      int index = (x + y * planeSize)*2;

      texCoords[index]   = map(x, 0, planeSize, 0.0, 1.0);
      texCoords[index+1] = map(y, 0, planeSize, 0.0, 1.0);
    }
  }

  posBuffer.rewind();
  posBuffer.put(positions);
  posBuffer.rewind();

  colourBuffer.rewind();
  colourBuffer.put(colours);
  colourBuffer.rewind();

  texCoordsBuffer.rewind();
  texCoordsBuffer.put(texCoords);
  texCoordsBuffer.rewind();

  indexBuffer.rewind();
  indexBuffer.put(indices);
  indexBuffer.rewind();
}  

void labelVertices() {
  for (int y = 0; y < planeSize; y++) {
    for (int x = 0; x < planeSize; x++) {
      int index = (x + y * planeSize)*4;
      text("v"+index/4, positions[index], positions[index+1], positions[index+2]);
    }
  }
}

FloatBuffer allocateDirectFloatBuffer(int n) {
  return ByteBuffer.allocateDirect(n * Float.BYTES).order(ByteOrder.nativeOrder()).asFloatBuffer();
}

IntBuffer allocateDirectIntBuffer(int n) {
  return ByteBuffer.allocateDirect(n * Integer.BYTES).order(ByteOrder.nativeOrder()).asIntBuffer();
}

ByteBuffer allocateDirectByteBuffer(int n) {
  return ByteBuffer.allocateDirect(n * Byte.BYTES).order(ByteOrder.nativeOrder());
}