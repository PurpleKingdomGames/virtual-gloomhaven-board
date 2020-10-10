using System;
using System.Linq;

namespace VirtualGloomhavenBoard.Models {
    public static class GameRoom {

        private const int CODE_LENGTH = 10;
        private static readonly char[] ValidChars = new[] {
            'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h',
            'j', 'k', 'm', 'n', 'p', 'q', 'r', 's',
            't', 'w', 'x', 'y', 'z', 'A', 'B', 'C',
            'D', 'E', 'F', 'G', 'H', 'J', 'K', 'M',
            'N', 'P', 'R', 'S', 'T', 'W', 'X', 'Y',
            'Z', '2', '3', '4', '5', '6', '7', '8',
            '9'
        };

        public static string GenerateCode(int? seed) {
            string code = string.Empty;
            Random rnd = seed == null ? new Random() : new Random(seed.Value);

            for (int i = 0; i < CODE_LENGTH; i++)
                code += ValidChars[rnd.Next(0, ValidChars.Length)];

            return code.Substring(0, 5) + "-" + code[5..];
        }

        public static bool ValidateCode(string roomCode) {
            string code = roomCode.Replace("-", "");
            return code.Length == CODE_LENGTH && roomCode.Replace("-", "").All(c => ValidChars.Contains(c));
        }
    }
}