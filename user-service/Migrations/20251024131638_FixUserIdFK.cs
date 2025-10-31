using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace user_service.Migrations
{
    /// <inheritdoc />
    public partial class FixUserIdFK : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_DriverRegisters_AspNetUsers_UserId1",
                table: "DriverRegisters");

            migrationBuilder.DropIndex(
                name: "IX_DriverRegisters_UserId1",
                table: "DriverRegisters");

            migrationBuilder.DropColumn(
                name: "UserId1",
                table: "DriverRegisters");

            migrationBuilder.AlterColumn<string>(
                name: "UserId",
                table: "DriverRegisters",
                type: "nvarchar(450)",
                nullable: false,
                oldClrType: typeof(Guid),
                oldType: "uniqueidentifier");

            migrationBuilder.CreateIndex(
                name: "IX_DriverRegisters_UserId",
                table: "DriverRegisters",
                column: "UserId");

            migrationBuilder.AddForeignKey(
                name: "FK_DriverRegisters_AspNetUsers_UserId",
                table: "DriverRegisters",
                column: "UserId",
                principalTable: "AspNetUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_DriverRegisters_AspNetUsers_UserId",
                table: "DriverRegisters");

            migrationBuilder.DropIndex(
                name: "IX_DriverRegisters_UserId",
                table: "DriverRegisters");

            migrationBuilder.AlterColumn<Guid>(
                name: "UserId",
                table: "DriverRegisters",
                type: "uniqueidentifier",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(450)");

            migrationBuilder.AddColumn<string>(
                name: "UserId1",
                table: "DriverRegisters",
                type: "nvarchar(450)",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_DriverRegisters_UserId1",
                table: "DriverRegisters",
                column: "UserId1");

            migrationBuilder.AddForeignKey(
                name: "FK_DriverRegisters_AspNetUsers_UserId1",
                table: "DriverRegisters",
                column: "UserId1",
                principalTable: "AspNetUsers",
                principalColumn: "Id");
        }
    }
}
