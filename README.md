# CollectiveVoting-Bash

An interactive terminal application that lets a group reach a decision through anonymous, code-based voting.

The project started as an assignment for the Operating Systems course at the Bucharest University of Economic Studies (ASE, CSIE) and was later extended with new functionality. Its purpose is to simulate a small voting process entirely in Bash: distributing one-time access codes, collecting votes securely and presenting the outcome in a clear, readable form.

## Key Functionality

- Vote using a personal access code, with each code accepted only once
- Choose from a configurable list of options loaded from a text file
- View live results for every option:
  - number of votes
  - percentage of the total
  - a horizontal progress bar
  - the winning option, or the tied options when there is no clear winner
- Generate any number of new access codes, guaranteed to be unique
- Receive color-coded feedback: green for confirmed actions, red for errors
- Exit cleanly at any point, including on end of input (Ctrl+D)

## Built With

- Bash scripting (functions, arrays, arithmetic expansion, regular expressions)
- Core Unix utilities: `grep`, `tr`, `xargs`, `wc`, `head`, `printf`
- `/dev/urandom` as the source of randomness for code generation
- Plain text files for persistent storage

## Repository Layout

```text
.
├── votare.sh          # Application entry point and logic
├── coduri.txt         # Valid access codes (sample data included)
├── optiuni.txt        # Voting options, one per line
├── docs/
│   └── DOCUMENTATIE.pdf   # Original course documentation (Romanian)
└── README.md
```

Two additional files are created automatically on first run and are not tracked by Git:

| File | Contents |
|---|---|
| `rezultate.txt` | One recorded vote per line (the selected option) |
| `coduri_folosite.txt` | Access codes that have already been used |

Votes and codes are stored separately, so the results file contains no information about who voted for what.

## Getting Started

1. Clone the repository:

```bash
git clone https://github.com/alexiacristea/CollectiveVoting-Bash.git
cd CollectiveVoting-Bash
```

2. Grant execution permission:

```bash
chmod +x votare.sh
```

3. Launch the application:

```bash
./votare.sh
```

Five sample codes (`COD1000` to `COD1004`) are provided so the application can be tried out right away.

## Main Menu

```text
=== Sistem de Vot Colectiv ===
1. Voteaza
2. Vizualizeaza rezultatele voturilor
3. Genereaza coduri noi de vot
4. Iesire din aplicatie
```

Sample results screen:

```text
Rezultate vot:
  A  ░░░░░░░░░░░░░░░░░░░░   0%  (0 voturi)
  B  █████████████░░░░░░░  66%  (2 voturi)
  C  ██████░░░░░░░░░░░░░░  33%  (1 vot)
Totalul voturilor exprimate este: 3
Castigator: B
```

## Input Handling

Every value entered by the user is checked before it affects the stored data:

- Access codes cannot be empty and may contain only letters and digits
- A code must be present in `coduri.txt`; matching is case-insensitive and tolerant of Windows line endings
- A code that has already been used is rejected
- The selected option must exactly match one of the available options
- The number of codes to generate must be an integer between 1 and 1000
- The main menu accepts only the listed choices

## Skills Demonstrated

- Structuring a shell script into small, single-purpose functions
- Separating configuration and data from program logic
- Persisting state with plain text files and safe appending
- Building an interactive, menu-driven command-line interface
- Validating input defensively and reporting errors clearly
- Using operating system resources such as `/dev/urandom` and terminal detection