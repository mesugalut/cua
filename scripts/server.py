import logging

from computer_server import Server


def main():
    server = Server("0.0.0.0", 8000, log_level=logging.DEBUG)  # type: ignore[arg-type]
    server.start()


if __name__ == "__main__":
    main()
