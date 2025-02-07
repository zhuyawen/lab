// Copyright (C) 2017 Google Inc.
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along
// with this program; if not, write to the Free Software Foundation, Inc.,
// 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
////////////////////////////////////////////////////////////////////////////////

#ifndef DML_DEEPMIND_ENGINE_CONTEXT_GAME_H_
#define DML_DEEPMIND_ENGINE_CONTEXT_GAME_H_

#include <array>
#include <cstddef>
#include <string>
#include <unordered_map>

#include "deepmind/include/deepmind_calls.h"
#include "deepmind/lua/lua.h"
#include "deepmind/lua/n_results_or.h"

namespace deepmind {
namespace lab {

// Represents a player's state in world units.
struct PlayerView {
  std::array<double, 3> pos;        // Position (forward, left, up).
  std::array<double, 3> vel;        // World velocity (forward, left, up).
  std::array<double, 3> angles;     // Orientation degrees (pitch, yaw, roll).
  std::array<double, 3> anglesVel;  // Angular velocity in degrees.
  int team_score;                   // Number of times we captured a flag.
  int other_team_score;             // Number of times others captured a flag.
  int player_id;
  int timestamp_msec;               // Engine time in msec of the view.
  double height;                    // View height.
};

// Receive calls from lua_script.
class ContextGame {
 public:
  // Optional override for reading contents of a file.
  using Reader = bool(const char* file_name, char** buff, std::size_t* size);

  ContextGame(const char* executable_runfiles,
              const DeepmindCalls* deepmind_calls, Reader* file_reader_override,
              std::string temp_folder)
      : deepmind_calls_(deepmind_calls),
        map_finished_(false),
        player_view_{},
        executable_runfiles_(executable_runfiles),
        file_reader_override_(file_reader_override),
        temp_folder_(std::move(temp_folder)) {}

  ~ContextGame();

  // Returns an event module. A pointer to ContextGame must exist in the up
  // value. [0, 1, -]
  static lua::NResultsOr Module(lua_State* L);

  int Init();
  void NextMap() { player_view_.timestamp_msec = 0; }

  // Returns whether we should finish the current map.
  bool MapFinished() const { return map_finished_; }

  // Sets whether the current map should finish.
  void SetMapFinished(bool map_finished) { map_finished_ = map_finished; }

  // The path level scripts should use for temporary files.
  const std::string& TempFolder() const { return temp_folder_; }

  const std::string& ExecutableRunfiles() const { return executable_runfiles_; }

  const DeepmindCalls* Calls() const { return deepmind_calls_; }

  void AddTextureHandle(std::string name, int handle);

  // Retrieves the handle for a named texture marked for update.
  // Returns whether a matching handle was found.
  bool TextureHandle(const std::string& name, int* handle) const;

  // Set latest player state.
  void SetPlayerState(const float pos[3], const float vel[3],
                             const float angles[3], float height,
                             int team_score, int other_team_score,
                             int player_id, int timestamp_msec);

  // Get latest predicted player view. (This is where the game renders from.)
  const PlayerView& GetPlayerView() {
    return player_view_;
  }

  Reader* FileReaderOverride() { return file_reader_override_; }

  // Retrieves what to render when render_custom_view engine command is called.
  // Returns whether to render the player or not.
  void GetCustomView(int* width, int* height, float position[3],
                      float view_angles[3], bool* render_player) const;

  // Used to store the current view for rendering when render_custom_view engine
  // command is called.
  void SetCustomView(int width, int height, const std::array<float, 3>& pos,
                     const std::array<float, 3>& eye, bool render_player);

 private:
  // Calls into the engine.
  const DeepmindCalls* deepmind_calls_;

  // Flag that can be set from the game to finish the current map.
  bool map_finished_;

  PlayerView player_view_;

  // Path to executables runfiles.
  std::string executable_runfiles_;

  // Optional override for reading contents of a file.
  Reader* file_reader_override_;

  // The path level scripts should use for temporary files.
  std::string temp_folder_;
  bool temp_folder_owned_;

  int camera_width_;
  int camera_height_;
  std::array<float, 3> camera_position_;
  std::array<float, 3> camera_view_angles_;
  bool camera_render_player_;
};

}  // namespace lab
}  // namespace deepmind

#endif  // DML_DEEPMIND_ENGINE_CONTEXT_GAME_H_
