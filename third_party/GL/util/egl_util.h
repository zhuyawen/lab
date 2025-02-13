// Copyright 2017 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////////

#ifndef THIRD_PARTY_GL_UTIL_EGL_UTIL_H_
#define THIRD_PARTY_GL_UTIL_EGL_UTIL_H_

#include <EGL/egl.h>

#ifdef __cplusplus
extern "C" {
#endif

// Creates and initializes an EGL display at the specified device_index. Unlike
// the standard eglGetDisplay(), this function takes a device_index, iterates
// through all the available devices on the machine using EGL extensions, and
// returns the Nth successfully initialized EGLDisplay. This allows us to get a
// valid EGL display on multi-GPU machines, where we limit access to a sub-set
// of the available GPU devices. Returns an initialized EGLDisplay or
// EGL_NO_DISPLAY on error.
EGLDisplay CreateInitializedEGLDisplayAtIndex(int device_index);

// Helper function to create EGL display at device index 0.
EGLDisplay CreateInitializedEGLDisplay();

// Helper function to only call eglTerminate() once all instances created from
// CreateInitializedEGLDisplay() have been terminated. This is necessary because
// calling eglTerminate will invalidate *all* contexts associated with a given
// display within the same address space.
EGLBoolean TerminateInitializedEGLDisplay(EGLDisplay display);

#ifdef __cplusplus
}  // extern "C"
#endif

#endif  // THIRD_PARTY_GL_UTIL_EGL_UTIL_H_
