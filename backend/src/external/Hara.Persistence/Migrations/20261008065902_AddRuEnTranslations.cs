using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Hara.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddRuEnTranslations : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "DescriptionEn",
                table: "Restaurants",
                type: "character varying(4000)",
                maxLength: 4000,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "DescriptionRu",
                table: "Restaurants",
                type: "character varying(4000)",
                maxLength: 4000,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "AnswerEn",
                table: "FaqItems",
                type: "character varying(4000)",
                maxLength: 4000,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "AnswerRu",
                table: "FaqItems",
                type: "character varying(4000)",
                maxLength: 4000,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "QuestionEn",
                table: "FaqItems",
                type: "character varying(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "QuestionRu",
                table: "FaqItems",
                type: "character varying(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "DescriptionEn",
                table: "AboutUsContents",
                type: "character varying(8000)",
                maxLength: 8000,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "DescriptionRu",
                table: "AboutUsContents",
                type: "character varying(8000)",
                maxLength: 8000,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "DescriptionEn",
                table: "Restaurants");

            migrationBuilder.DropColumn(
                name: "DescriptionRu",
                table: "Restaurants");

            migrationBuilder.DropColumn(
                name: "AnswerEn",
                table: "FaqItems");

            migrationBuilder.DropColumn(
                name: "AnswerRu",
                table: "FaqItems");

            migrationBuilder.DropColumn(
                name: "QuestionEn",
                table: "FaqItems");

            migrationBuilder.DropColumn(
                name: "QuestionRu",
                table: "FaqItems");

            migrationBuilder.DropColumn(
                name: "DescriptionEn",
                table: "AboutUsContents");

            migrationBuilder.DropColumn(
                name: "DescriptionRu",
                table: "AboutUsContents");
        }
    }
}
