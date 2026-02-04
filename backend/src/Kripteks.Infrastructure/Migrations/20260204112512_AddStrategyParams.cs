using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Kripteks.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddStrategyParams : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "StrategyParams",
                table: "Bots",
                type: "nvarchar(max)",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "StrategyParams",
                table: "Bots");
        }
    }
}
