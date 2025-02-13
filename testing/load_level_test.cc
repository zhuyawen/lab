#include <glob.h>

#include <array>
#include <string>

#include "deepmind/support/logging.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"
#include "deepmind/support/test_srcdir.h"
#include "deepmind/util/files.h"
#include "public/dmlab.h"
#include "testing/env_observation.h"

namespace deepmind {
namespace lab {
namespace {

using ::testing::ElementsAre;

const char* test_script = nullptr;

// Tests that the level loads and that we're able to advance a few steps in the
// environment.
TEST(LoadLevelTest, LoadLevelAndWait) {
  std::string runfiles_path(TestSrcDir());

  DeepMindLabLaunchParams params = {};
  params.runfiles_path = runfiles_path.c_str();
  params.renderer = DeepMindLabRenderer_Software;

  EnvCApi env_c_api;
  void* context;
  dmlab_connect(&params, &env_c_api, &context);
  ASSERT_EQ(env_c_api.setting(context, "width", "64"), 0);
  ASSERT_EQ(env_c_api.setting(context, "height", "36"), 0);
  ASSERT_EQ(env_c_api.setting(context, "logToStdErr", "true"), 0);
  ASSERT_EQ(env_c_api.setting(context, "fps", "15"), 0);
  ASSERT_EQ(env_c_api.setting(context, "invocationMode", "testbed"), 0);
  ASSERT_EQ(env_c_api.setting(context, "levelName", test_script), 0);

// When running under TSAN, switch to the interpreted VM ("1"), which is
// instrumentable.
#ifndef __has_feature
#define __has_feature(x) 0
#endif
#if __has_feature(thread_sanitizer)
  ASSERT_EQ(env_c_api.setting(context, "vmMode", "interpreted"), 0);
#endif

  ASSERT_EQ(env_c_api.init(context), 0);
  env_c_api.start(context, 0 /*episode*/, 1 /*seed*/);

  double reward;
  env_c_api.advance(context, 10 /*steps*/, &reward);

  EnvCApi_Observation observation;
  env_c_api.observation(context, 0, &observation);
  EnvObservation<unsigned char> test_observation(observation);

  EXPECT_THAT(test_observation.shape(), ElementsAre(36, 64, 3));
}

// Invokes seed_test.lua to check that the random seed is initialised in the
// start method of the level.
TEST(LoadLevelTest, RandomSeedTest) {
  const std::string runfiles_path = TestSrcDir();

  DeepMindLabLaunchParams params = {};
  params.runfiles_path = runfiles_path.c_str();
  params.renderer = DeepMindLabRenderer_Software;

  EnvCApi env_c_api;
  void* context;
  ASSERT_EQ(dmlab_connect(&params, &env_c_api, &context), 0);
  ASSERT_EQ(env_c_api.setting(context, "levelName", "tests/seed_test"),
            0);
  ASSERT_EQ(env_c_api.setting(context, "testLevelScript", test_script), 0);

// When running under TSAN, switch to the interpreted VM ("1"), which is
// instrumentable.
#ifndef __has_feature
#define __has_feature(x) 0
#endif
#if __has_feature(thread_sanitizer)
  ASSERT_EQ(env_c_api.setting(context, "vmMode", "interpreted"), 0);
#endif

  if (env_c_api.init(context) != 0) {
    FAIL() << "Inspect output for errors.";
  }
  env_c_api.release_context(context);
}

}  // namespace
}  // namespace lab
}  // namespace deepmind

int main(int argc, char** argv) {
  ::testing::InitGoogleTest(&argc, argv);
  QCHECK_EQ(argc, 2) << "Usage: load_level_test <filename>";
  deepmind::lab::test_script = argv[1];

  return RUN_ALL_TESTS();
}
