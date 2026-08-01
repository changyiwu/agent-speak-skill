"""speak_stream.py 的隔離測試；不連網、不啟動真實播放器。"""

from __future__ import annotations

import contextlib
import io
import runpy
import sys
import types
import unittest
from pathlib import Path
from unittest import mock


SCRIPT = Path(__file__).resolve().parents[1] / "speak" / "speak_stream.py"


class FakeStdin:
    def __init__(self, fail_write: bool = False) -> None:
        self.fail_write = fail_write
        self.data = bytearray()

    def write(self, data: bytes) -> None:
        if self.fail_write:
            raise BrokenPipeError
        self.data.extend(data)

    def flush(self) -> None:
        return None

    def close(self) -> None:
        return None


class FakeProcess:
    def __init__(self, return_code: int = 0, fail_write: bool = False) -> None:
        self.stdin = FakeStdin(fail_write=fail_write)
        self.return_code = return_code

    def wait(self, timeout: int | None = None) -> int:
        return self.return_code

    def terminate(self) -> None:
        return None


def fake_edge_tts(chunks: list[dict[str, object]]) -> types.ModuleType:
    module = types.ModuleType("edge_tts")

    class Communicate:
        def __init__(self, text: str, voice: str) -> None:
            self.text = text
            self.voice = voice

        async def stream(self):
            for chunk in chunks:
                yield chunk

    module.Communicate = Communicate
    return module


class SpeakStreamTests(unittest.TestCase):
    def run_stream(
        self,
        *,
        chunks: list[dict[str, object]],
        player_code: int = 0,
        fail_write: bool = False,
        player_present: bool = True,
    ) -> tuple[int, str, str]:
        process = FakeProcess(return_code=player_code, fail_write=fail_write)
        stdout = io.StringIO()
        stderr = io.StringIO()

        def which(name: str) -> str | None:
            if player_present and name == "mpv":
                return "mock-mpv"
            return None

        with (
            mock.patch.dict(sys.modules, {"edge_tts": fake_edge_tts(chunks)}),
            mock.patch("shutil.which", side_effect=which),
            mock.patch("subprocess.Popen", return_value=process),
            mock.patch.object(sys, "argv", [str(SCRIPT), "測試文字"]),
            contextlib.redirect_stdout(stdout),
            contextlib.redirect_stderr(stderr),
        ):
            try:
                runpy.run_path(str(SCRIPT), run_name="__main__")
            except SystemExit as exc:
                return int(exc.code or 0), stdout.getvalue(), stderr.getvalue()
        return 0, stdout.getvalue(), stderr.getvalue()

    def test_success_reports_metrics(self) -> None:
        code, stdout, _ = self.run_stream(
            chunks=[{"type": "audio", "data": b"audio"}]
        )
        self.assertEqual(code, 0)
        self.assertIn("first_audio_chunk_s=", stdout)
        self.assertIn("total_s=", stdout)

    def test_missing_player_returns_three(self) -> None:
        code, _, _ = self.run_stream(chunks=[], player_present=False)
        self.assertEqual(code, 3)

    def test_broken_pipe_returns_four(self) -> None:
        code, _, stderr = self.run_stream(
            chunks=[{"type": "audio", "data": b"audio"}], fail_write=True
        )
        self.assertEqual(code, 4)
        self.assertIn("未正常完成", stderr)

    def test_nonzero_player_exit_returns_four(self) -> None:
        code, _, _ = self.run_stream(
            chunks=[{"type": "audio", "data": b"audio"}], player_code=1
        )
        self.assertEqual(code, 4)


if __name__ == "__main__":
    unittest.main()
